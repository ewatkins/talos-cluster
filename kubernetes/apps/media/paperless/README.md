# [Paperless-ngx](https://docs.paperless-ngx.com/)

Paperless-ngx is the document management system for this cluster. It ingests documents from a watched NFS directory, runs OCR to make them full-text searchable, and provides a web interface for browsing and tagging the archive.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://paperless.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Authentication | Keycloak OIDC | Users sign in with cluster SSO via `allauth.socialaccount.providers.openid_connect` |
| Database | PostgreSQL via `paperless-db-secret` | Stores document metadata, tags, correspondents, and OCR text |
| Task queue | Dragonfly (Redis-compatible) | Queues OCR and document processing jobs |
| Document storage | NFS `caspian.local:/mnt/user/paperless` | Stores original documents and OCR output |
| OCR language | Dutch (`nld`) | Primary language for OCR processing |
| Consumer polling | Every 60 seconds, recursive | Watches for new documents dropped into the consume directory |

## Links

- [Documentation](https://docs.paperless-ngx.com/)
- [GitHub Repository](https://github.com/paperless-ngx/paperless-ngx)
