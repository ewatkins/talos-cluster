# [BookOrbit](https://github.com/bookorbit/bookorbit)

BookOrbit is the whole book stack: it takes requests, fetches them through
Prowlarr and SABnzbd, files them into the eBook and audiobook libraries, and serves
them, with a web reader, Kobo and KOReader sync, OPDS, read-aloud and reading
statistics.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/bookorbit/bookorbit:3.4.0` | Upstream tags have no `v` prefix |
| URL | `https://books.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target); also `APP_URL` |
| Port | `3000` | Service exposes it on `80` |
| Database | PG17 `bookorbit` | Direct to `crunchy-postgres-17-primary`, **not** pgbouncer (see below); creds from `bookorbit-db-secret` |
| App data PVC | `bookorbit-data`, 10Gi (`nfs-slow`) | Mounted at `/data`; covers and the upload bucket |
| Run as user/group | `99:100` | Matches the *arr apps and the `arrdata` share owner |
| Memory limit | `2Gi` | The entrypoint sizes the Node heap to 75% of it |
| Secrets | Bitwarden `bookorbit-secret` | See below |

## Role in the book stack

Compared with the video stack, BookOrbit covers three seats at once:

| Role | Video | Books |
| --- | --- | --- |
| Requests | Seerr | BookOrbit |
| Acquire and organise | Radarr / Sonarr | BookOrbit |
| Indexers | Prowlarr | Prowlarr |
| Download | SABnzbd | SABnzbd, category `bookorbit` |
| Play / read | Jellyfin | BookOrbit |

Chaptarr (acquisition) and Cantinarr (a request portal for it) were tried first
and removed on 2026-10-16 in favour of this. Books they fetched stay in the
library folders.

### Requests

Configured in the UI under Settings → System → Requests:

| Setting | Value |
| --- | --- |
| Indexer manager | Prowlarr `http://prowlarr.media.svc.cluster.local` + Prowlarr API key |
| Download client | SABnzbd `sab.ewatkins.dev:443` SSL, category **`bookorbit`** |
| Path mapping | `/data/usenet/complete/` → `/mnt/arrdata/usenet/complete/` |
| Destination library | `Books` for both e-books and audiobooks |

BookOrbit checks the SABnzbd category exists when the client is saved, and only
acts on downloads it tagged itself. The download client's credentials are stored
encrypted with `BOOK_REQUEST_ENCRYPTION_KEY`.

## Storage layout

The whole `arrdata` share is mounted once, writable, at `/mnt/arrdata`, exactly as
the *arr apps mount it, so a path means the same thing in BookOrbit and Sonarr:

| Container path | Purpose |
| --- | --- |
| `/mnt/arrdata/media/books` | The `Books` library: one folder per book, holding the e-book and the audiobook together |
| `/mnt/arrdata/usenet/complete` | SABnzbd completed downloads (`bookorbit/` category folder) |
| `/mnt/arrdata/bookorbit/dock` | `BOOK_DOCK_PATH`: request imports and uploads land here before filing |

**Why not subfolder mounts.** BookOrbit first mounted these folders separately so
some could be read-only. On Unraid that breaks: `/mnt/user` is a FUSE
(shfs) filesystem, and an NFS mount *rooted at a subfolder* goes `Stale file
handle` once shfs forgets that folder's inode, by default after ~330 s idle
(`fuse_remember`). It hit `bookorbit/` ten minutes after a restart and failed a
request at the filing step with `ENOENT`; the same thing hit this app's NFS-backed
data PVC once. The share root does not go stale, which is why every *arr app mounts
it.

Imports copy rather than hardlink (`EXDEV` in the log is expected): the files cross
from SABnzbd's folder into the dock.

## Libraries

Created in the UI (Settings → Libraries), not in Git. `LIBRARY_BROWSE_ROOT` limits
the folder picker to `/mnt/arrdata`.

| Library | Folder | Organization |
| --- | --- | --- |
| Books | `/mnt/arrdata/media/books` | Folder per book |

**One library on purpose.** BookOrbit pairs an e-book with its audiobook only when
both are files of the same book, which means the same folder in the same
folder-per-book library. Requested together ("Request both") into `Books`, the two
formats arrive as one book with an e-book side and an audio side; split across two
libraries they arrive as two books. `media/ebooks` and `media/audiobooks` were
merged into `media/books` on 2026-10-16 for this.

The dock must stay outside both library folders: BookOrbit refuses a dock and a
library nested in each other.

## Secrets

Bitwarden item `bookorbit-secret`:

| Field | Env | Generate |
| --- | --- | --- |
| `jwt_secret` | `JWT_SECRET` | `openssl rand -hex 32` |
| `podcast_encryption_key` | `PODCAST_ENCRYPTION_KEY` | `openssl rand -hex 32` (independent of `jwt_secret`) |
| `setup_bootstrap_token` | `SETUP_BOOTSTRAP_TOKEN` | `openssl rand -hex 32` |
| `email_encryption_key` | `EMAIL_ENCRYPTION_KEY` | `openssl rand -hex 32` |
| `book_request_encryption_key` | `BOOK_REQUEST_ENCRYPTION_KEY` | `openssl rand -hex 32` (64 hex chars; rotating it makes stored indexer credentials unreadable) |

## OIDC

Configured in the UI (Settings → Authentication), stored in the database — there
are no OIDC env vars beyond `OIDC_ALLOW_LOCAL_ISSUERS=true`, needed because
`keycloak.ewatkins.dev` resolves to a private address.

Keycloak client `bookorbit` in the `master` realm: client authentication **on**,
standard flow, valid redirect URI `https://books.ewatkins.dev/oauth2-callback`,
web origin `https://books.ewatkins.dev`. Issuer
`https://keycloak.ewatkins.dev/realms/master`. Local login stays enabled as the
recovery path (`DISABLE_LOCAL_AUTH` unset).

## Why not pgbouncer

node-postgres sends `statement_timeout` as a connection startup parameter, and
pgbouncer refuses unknown startup parameters. Migrations run on a plain
connection and pass, then the app dies at boot with `unsupported startup
parameter: statement_timeout`. The alternative, adding it to pgbouncer's
`ignore_startup_parameters`, would silently drop the timeout for every tenant of
the shared pooler, so BookOrbit uses the pguser secret's direct `host`/`port`
instead.

## `vector` extension caveat

Every start runs `CREATE EXTENSION IF NOT EXISTS` for `uuid-ossp`, `pg_trgm`,
`unaccent` and `vector` before migrating. The first three are trusted and the
`bookorbit` owner can create them; `vector` is not, so it has to exist before the
first boot or migrations fail. One-off, as the superuser:

```sql
\c bookorbit
CREATE EXTENSION IF NOT EXISTS vector;
```

`IF NOT EXISTS` skips the privilege check once it is installed. This is not
captured in Git and must be redone if the PG17 cluster
is rebuilt. Upstream ships PG18 (`pgvector/pgvector:pg18`); the migrations use
nothing PG18-specific.

## First run

The first admin is created through `/auth/setup`, which requires the
`x-setup-token` header to equal `SETUP_BOOTSTRAP_TOKEN`; the web setup screen asks
for it.

## Links

- [GitHub Repository](https://github.com/bookorbit/bookorbit)
- [Website](https://bookorbit.app)
