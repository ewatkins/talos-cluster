# [Outline](https://www.getoutline.com/)

Outline is the team knowledge base and wiki for this cluster's documentation. It integrates with Keycloak for SSO, Dragonfly for caching, PostgreSQL for document storage, and Minio for file attachments and uploads.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://notes.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Authentication | Keycloak OIDC | `OIDC_DISPLAY_NAME: Keycloak` — users log in with cluster SSO credentials |
| Database | PostgreSQL via `outline-db` secret | Stores documents, users, and collections |
| Cache | Dragonfly (Redis-compatible) | Session store and real-time collaboration support |
| Object storage | Minio at `s3.ewatkins.dev` | Stores file attachments and uploaded images |

## Links

- [Documentation](https://docs.getoutline.com/)
- [GitHub Repository](https://github.com/outline/outline)
