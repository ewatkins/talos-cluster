# [BookOrbit](https://github.com/bookorbit/bookorbit)

BookOrbit is the reading front end for the book collection: a web reader for eBooks
and audiobooks, Kobo and KOReader sync, OPDS, read-aloud and reading statistics.
[Chaptarr](../chaptarr/README.md) stays the system of record for acquiring and
organising books; BookOrbit reads Chaptarr's library and serves it.

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

The book stack mirrors the video one, with BookOrbit in Jellyfin's seat:

| Role | Video | Books |
| --- | --- | --- |
| Requests | Seerr | Chaptarr UI (Cantinarr under trial) |
| Acquire and organise | Radarr / Sonarr | Chaptarr |
| Indexers | Prowlarr | Prowlarr |
| Download | SABnzbd | SABnzbd, category `books` |
| Play / read | Jellyfin | BookOrbit |

Chaptarr remains the system of record.

### BookOrbit requests (on trial)

BookOrbit's own request pipeline is enabled as a comparison against Chaptarr:
Prowlarr → SABnzbd → dock → BookOrbit's own library. Configured in the UI under
Settings → System → Requests:

| Setting | Value |
| --- | --- |
| Indexer manager | Prowlarr `http://prowlarr.media.svc.cluster.local` + Prowlarr API key |
| Download client | SABnzbd `sab.ewatkins.dev:443` SSL, category **`bookorbit`** |
| Path mapping | `/data/usenet/complete/` → `/mnt/arrdata/usenet/complete/` |
| Destination library | `BookOrbit` (`/mnt/arrdata/bookorbit/library`) |

The `bookorbit` SABnzbd category (folder `bookorbit`) is deliberately separate
from Chaptarr's `books`: Chaptarr's completed-download handling imports and
removes matching items in its category even when it did not grab them, so a
shared category would race BookOrbit's import. BookOrbit checks the category
exists when the client is saved, and only acts on downloads it tagged itself.

Books fetched this way live only in the BookOrbit library: Chaptarr does not
track or upgrade them.

## Storage layout

The two Chaptarr root folders are mounted **read-only**, at the same container paths
the *arr apps use, so a path means the same thing in BookOrbit and Chaptarr. Only
BookOrbit's own area is writable:

| Mount | NFS path (`storage.ewatkins.dev`) | Mode | Purpose |
| --- | --- | --- | --- |
| `/mnt/arrdata/media/ebooks` | `/mnt/user/arrdata/media/ebooks` | ro | Chaptarr eBook library |
| `/mnt/arrdata/media/audiobooks` | `/mnt/user/arrdata/media/audiobooks` | ro | Chaptarr audiobook library |
| `/mnt/arrdata/usenet/complete` | `/mnt/user/arrdata/usenet/complete` | ro | SABnzbd completed downloads; imports copy out, cleanup via SAB's API |
| `/mnt/arrdata/bookorbit` | `/mnt/user/arrdata/bookorbit` | rw | `dock/` (`BOOK_DOCK_PATH`) and `library/` |

Features that write back into files (embedding metadata, renaming, moving, bulk
rename) fail by design on the Chaptarr libraries; fix metadata in Chaptarr.
`/mnt/user/arrdata/bookorbit` must exist on the share (owned `99:100`) before the
pod can start.

## Libraries

Created in the UI (Settings → Libraries), not in Git. `LIBRARY_BROWSE_ROOT` limits
the folder picker to `/mnt/arrdata`.

| Library | Folder | Owner |
| --- | --- | --- |
| eBooks | `/mnt/arrdata/media/ebooks` | Chaptarr (read-only here) |
| Audiobooks | `/mnt/arrdata/media/audiobooks` | Chaptarr (read-only here) |
| BookOrbit | `/mnt/arrdata/bookorbit/library` | BookOrbit; destination for its own requests |

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

`IF NOT EXISTS` skips the privilege check once it is installed. Like Chaptarr's
ownership fix this is not captured in Git and must be redone if the PG17 cluster
is rebuilt. Upstream ships PG18 (`pgvector/pgvector:pg18`); the migrations use
nothing PG18-specific.

## First run

The first admin is created through `/auth/setup`, which requires the
`x-setup-token` header to equal `SETUP_BOOTSTRAP_TOKEN`; the web setup screen asks
for it.

## Links

- [GitHub Repository](https://github.com/bookorbit/bookorbit)
- [Website](https://bookorbit.app)
