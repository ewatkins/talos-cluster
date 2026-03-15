# [Forgejo](https://forgejo.org/)

Forgejo is the self-hosted Git service for this cluster. It provides repository hosting, issue tracking, pull requests, and CI/CD via Forgejo Actions.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://git.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Registration | External accounts only | `ALLOW_ONLY_EXTERNAL_REGISTRATION: true` — the local sign-up form is disabled; accounts must be created by an admin or via a configured OAuth2 provider |
| OpenID | Disabled | `ENABLE_OPENID_SIGNIN` and `ENABLE_OPENID_SIGNUP` are both `false` |
| Database | PostgreSQL via `forgejo-db` secret | Stores repositories, issues, users, and settings |
| Cache / Queue | Dragonfly (Redis-compatible) | Used for session storage, task queues, and caching |
| Object storage | Minio at `s3.ewatkins.dev:443` | Stores LFS objects, release attachments, and avatars |
| Email | SMTP configured | Sends notifications for issues, PRs, and CI results |
| Metrics | Prometheus ServiceMonitor | Exposes Forgejo application metrics |

## Links

- [Documentation](https://forgejo.org/docs/latest/)
- [Helm Chart](https://codeberg.org/forgejo-contrib/forgejo-helm)
- [GitHub Repository (mirror)](https://github.com/go-gitea/gitea)
