# [BookOrbit](https://github.com/bookorbit/bookorbit)

BookOrbit is the reading front end for the book collection: a web reader for eBooks
and audiobooks, Kobo and KOReader sync, OPDS, read-aloud and reading statistics.
[Chaptarr](../chaptarr/README.md) stays the system of record for acquiring and
organising books; BookOrbit reads Chaptarr's library and serves it.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/bookorbit/bookorbit:3.4.0` | Upstream tags have no `v` prefix |
| URL | `https://bookorbit.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target); also `APP_URL` |
| Port | `3000` | Service exposes it on `80` |
| Database | PG17 `bookorbit` | Via pgbouncer (`pool_mode: session`); creds from `bookorbit-db-secret` |
| App data PVC | `bookorbit-data`, 10Gi (`nfs-slow`) | Mounted at `/data`; covers and the upload bucket |
| Run as user/group | `99:100` | Matches the *arr apps and the `arrdata` share owner |
| Memory limit | `2Gi` | The entrypoint sizes the Node heap to 75% of it |
| Secrets | Bitwarden `bookorbit-secret` | See below |

## Storage layout

Unlike the *arr apps, which mount the whole `arrdata` share once, BookOrbit mounts
four subdirectories separately so Chaptarr's folders can be read-only:

| Mount | NFS path (`storage.ewatkins.dev`) | Mode | Purpose |
| --- | --- | --- | --- |
| `/mnt/arrdata/media/ebooks` | `/mnt/user/arrdata/media/ebooks` | ro | Chaptarr eBook library |
| `/mnt/arrdata/media/audiobooks` | `/mnt/user/arrdata/media/audiobooks` | ro | Chaptarr audiobook library |
| `/mnt/arrdata/usenet/complete` | `/mnt/user/arrdata/usenet/complete` | ro | SABnzbd completed downloads |
| `/mnt/arrdata/bookorbit` | `/mnt/user/arrdata/bookorbit` | rw | `dock/` (`BOOK_DOCK_PATH`) and `library/` |

Container paths match the *arr apps' view of the share, so a path means the same
thing in BookOrbit, Chaptarr and Sonarr. Because the mounts are separate, hardlinks
between them fail with `EXDEV` and BookOrbit falls back to copying; for books that
is cheap. `/mnt/user/arrdata/bookorbit` must exist on the share before the pod can
start (`mkdir -p .../bookorbit/{dock,library}` as `99:100`).

## Libraries

Created in the UI (Settings → Libraries), not in Git:

| Library | Folder | Owner |
| --- | --- | --- |
| eBooks | `/mnt/arrdata/media/ebooks` | Chaptarr (read-only here) |
| Audiobooks | `/mnt/arrdata/media/audiobooks` | Chaptarr (read-only here) |
| BookOrbit | `/mnt/arrdata/bookorbit/library` | BookOrbit; destination for its own requests |

Features that write back into files (embedding metadata, renaming, moving) fail on
the Chaptarr libraries by design. Fix metadata in Chaptarr instead.

## Book requests

BookOrbit has its own request pipeline (indexer manager → download client → dock →
library), independent of Chaptarr. It is enabled, configured in the UI under
Settings → System → Requests:

| Setting | Value |
| --- | --- |
| Indexer manager | Prowlarr `http://prowlarr.media.svc.cluster.local` + Prowlarr API key |
| Download client | SABnzbd `sab.ewatkins.dev:443` SSL, category **`bookorbit`** |
| Path mapping | `/data/usenet/complete/` → `/mnt/arrdata/usenet/complete/` |
| Destination library | `BookOrbit` (`/mnt/arrdata/bookorbit/library`) |

The `bookorbit` SABnzbd category is deliberately separate from Chaptarr's `books`
so neither app sees the other's downloads in its queue. BookOrbit checks the
category exists when a client is saved. Credentials are stored encrypted with
`BOOK_REQUEST_ENCRYPTION_KEY`; rotating that key makes them unreadable.

Requests fulfilled here land in BookOrbit's own library, not Chaptarr's, and
Chaptarr will not track or upgrade them. To have Chaptarr own a title, add it in
Chaptarr instead.

## Secrets

Bitwarden item `bookorbit-secret`:

| Field | Env | Generate |
| --- | --- | --- |
| `jwt_secret` | `JWT_SECRET` | `openssl rand -hex 32` |
| `podcast_encryption_key` | `PODCAST_ENCRYPTION_KEY` | `openssl rand -hex 32` (independent of `jwt_secret`) |
| `setup_bootstrap_token` | `SETUP_BOOTSTRAP_TOKEN` | `openssl rand -hex 32` |
| `book_request_encryption_key` | `BOOK_REQUEST_ENCRYPTION_KEY` | `openssl rand -hex 32` (must be 64 hex chars) |
| `email_encryption_key` | `EMAIL_ENCRYPTION_KEY` | `openssl rand -hex 32` |

## OIDC

Configured in the UI (Settings → Authentication), stored in the database — there
are no OIDC env vars beyond `OIDC_ALLOW_LOCAL_ISSUERS=true`, needed because
`keycloak.ewatkins.dev` resolves to a private address.

Keycloak client `bookorbit` in the `master` realm: client authentication **on**,
standard flow, valid redirect URI `https://bookorbit.ewatkins.dev/oauth2-callback`,
web origin `https://bookorbit.ewatkins.dev`. Issuer
`https://keycloak.ewatkins.dev/realms/master`. Local login stays enabled as the
recovery path (`DISABLE_LOCAL_AUTH` unset).

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
