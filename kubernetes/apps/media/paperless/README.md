# [Paperless-ngx](https://docs.paperless-ngx.com/)

Paperless-ngx is the document management system for this cluster. It ingests documents from a watched NFS directory, runs OCR to make them full-text searchable, and provides a web interface for browsing, tagging, and managing the archive.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/paperless-ngx/paperless-ngx:2.20.10` | |
| URL | `https://paperless.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `8000` | HTTP |
| Timezone | `America/Chicago` | |
| Web workers | `2` | |
| Task workers | `2` | |
| Authentication | Keycloak OIDC via `allauth.socialaccount.providers.openid_connect` | OIDC server: `https://auth.ewatkins.dev/realms/master`; regular login form disabled; social account signups enabled, direct signups disabled |
| Database | PostgreSQL via CrunchyDB PGBouncer | `PAPERLESS_DBHOST` and credentials from `paperless-db-secret` ExternalSecret; uses `crunchy-postgres-pguser-paperless-admin` |
| Task queue / cache | Dragonfly at `dragonfly.database.svc.cluster.local:6379` | |
| NFS storage | `storage.ewatkins.dev:/mnt/user/paperless` | Mounted at `/data/nas`; provides consume, data, export, and media directories |
| Consume directory | `/data/nas/consume` | Polled every 60 seconds, recursive; subdirectories applied as tags |
| Data directory | `/data/nas/data` | |
| Export directory | `/data/nas/export` | |
| Media root | `/data/nas/media` | |
| OCR primary language | Dutch (`nld`) | |
| SMTP from address | `paperless@ewatkins.dev` | SMTP host/credentials from Bitwarden Secrets Manager |
| Memory limit | `2Gi` | |

## Secrets

Two ExternalSecrets are used (both refreshed every 15 minutes):

| Secret | Source | Contents |
| --- | --- | --- |
| `paperless-db-secret` | `crunchy-postgres` ClusterSecretStore | PostgreSQL host, port, user, password, database name (via PGBouncer) |
| `paperless-config-secret` | Bitwarden Secrets Manager | Admin credentials, Django secret key, SMTP settings, OIDC client ID and secret |

## Links

- [Documentation](https://docs.paperless-ngx.com/)
- [GitHub Repository](https://github.com/paperless-ngx/paperless-ngx)
