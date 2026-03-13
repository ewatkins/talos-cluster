# [Forgejo](https://forgejo.org/)

Forgejo is a lightweight, self-hosted Git service — a community-driven fork of Gitea. It provides repository hosting, issue tracking, pull requests, and CI/CD pipelines via Forgejo Actions.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `forgejo` |
| [`HelmRelease`][ref-helm-release] | `forgejo-runner` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `forgejo` v16.2.0 from the `forgejo` Helm repository
- Accessible at `https://git.ewatkins.dev`
- Registration is restricted to external accounts only (`ALLOW_ONLY_EXTERNAL_REGISTRATION: true`)
- Backed by PostgreSQL via `forgejo-db` secret
- Uses Dragonfly as a Redis-compatible cache, queue, and session store
- Object storage (attachments, LFS, etc.) via Minio at `s3.ewatkins.dev:443`
- SMTP email configured for notifications
- Prometheus metrics and ServiceMonitor enabled

## Links

- [Documentation](https://forgejo.org/docs/latest/)
- [Helm Chart](https://codeberg.org/forgejo-contrib/forgejo-helm)
- [GitHub Repository (mirror)](https://github.com/go-gitea/gitea)
