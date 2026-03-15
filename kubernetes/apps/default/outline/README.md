# [Outline](https://www.getoutline.com/)

A team knowledge base and wiki. Integrates with Keycloak for OIDC authentication, Dragonfly for caching, PostgreSQL (via PgBouncer) for document storage, Minio for file uploads, and SMTP for email notifications.

## Configuration

| Setting | Value |
| --- | --- |
| Chart | `bjw-s/app-template` (OCI, `app-template` OCIRepository) |
| Image | `outlinewiki/outline:1.5.0` |
| Port | 3000 |
| URL | `https://notes.ewatkins.dev` (internal gateway) |
| CPU request | 50m |
| Memory request | 256 Mi |
| Memory limit | 1 Gi |
| Redis / cache | `redis://dragonfly.database.svc.cluster.local:6379` |
| PostgreSQL | Via `outline-db` secret (PgBouncer endpoint from `crunchy-postgres-pguser-outline-admin`) |
| `PGSSLMODE` | `disable` |
| OIDC provider | Keycloak (`OIDC_DISPLAY_NAME: Keycloak`, `OIDC_CLIENT_ID: outline`) |
| OIDC scopes | `openid profile email` |
| OIDC username claim | `preferred_username` |
| S3 storage | Minio (credentials from `outline-secret`), private ACL |
| SMTP from address | `outline@ewatkins.dev` |
| `FORCE_HTTPS` | `false` (TLS terminated at gateway) |
| `ENABLE_UPDATES` | `false` |
| Default language | `en_US` |
| Health check path | `/_health` |

## Secrets

| Secret | Source | Contents |
| --- | --- | --- |
| `outline-secret` | Bitwarden (key: `outline-secret`) | `SECRET_KEY`, `UTILS_SECRET`, OIDC client secret and URIs, S3 credentials and bucket config |
| `outline-smtp` | Bitwarden (key: `smtp`) | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_SECURE` |
| `outline-db` | `crunchy-postgres` ClusterSecretStore | `DATABASE_URL` built from the `crunchy-postgres-pguser-outline-admin` secret |

All ExternalSecrets refresh every 15 minutes. The deployment restarts automatically when secrets change (`reloader.stakater.com/auto: "true"`).

## Links

- [Documentation](https://docs.getoutline.com/)
- [GitHub Repository](https://github.com/outline/outline)
