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

Chaptarr remains the system of record. BookOrbit does not use Prowlarr or SABnzbd:
that would bypass Chaptarr with a second category, and sharing Chaptarr's `books`
category would race Chaptarr's completed-download handling, which imports and
removes matching items it did not grab.

### Direct downloads (on trial)

BookOrbit's request pipeline is enabled for one source only, as a comparison
against Chaptarr: the **libgen** indexer plugin from
[`orbit-plugins/bookorbit-plugins-extra`](https://github.com/orbit-plugins/bookorbit-plugins-extra)
(ebooks only, no credential, grabs a direct file — no download client).

- BookOrbit ships no sources; plugins are installed by hand in Settings → System →
  Requests from the plugin's raw `index.mjs`, and land in `/data/plugins/indexers/`.
- **A plugin runs inside the BookOrbit process** with its database, keys and files.
  Read it before installing. libgen 2.0.0 was reviewed on 2026-10-16: one
  dependency-free file, network only through `host.fetch` (`libgen.li` search,
  `libgen.download` files). It self-updates from that repo; updates are checked
  against the Ed25519 key pinned in the installed copy.
- From the cluster, `libgen.download` answers; the default search mirror `libgen.li`
  did not on 2026-10-16. Set another mirror in the plugin's base URL if searches
  time out.
- Files stage in `/data/request-downloads`, import into the dock, and finalize into
  the **BookOrbit** library. They are not in Chaptarr's library and Chaptarr will
  not track or upgrade them.

## Storage layout

The two Chaptarr root folders are mounted **read-only**, at the same container paths
the *arr apps use, so a path means the same thing in BookOrbit and Chaptarr. Only
BookOrbit's own area is writable:

| Mount | NFS path (`storage.ewatkins.dev`) | Mode | Purpose |
| --- | --- | --- | --- |
| `/mnt/arrdata/media/ebooks` | `/mnt/user/arrdata/media/ebooks` | ro | Chaptarr eBook library |
| `/mnt/arrdata/media/audiobooks` | `/mnt/user/arrdata/media/audiobooks` | ro | Chaptarr audiobook library |
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
| BookOrbit | `/mnt/arrdata/bookorbit/library` | BookOrbit; destination for direct downloads |

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
