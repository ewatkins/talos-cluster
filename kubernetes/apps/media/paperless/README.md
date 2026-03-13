# [Paperless-ngx](https://docs.paperless-ngx.com/)

Paperless-ngx is a document management system that transforms physical documents into a searchable online archive using OCR. It supports OIDC authentication and automated document ingestion.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `paperless` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/paperless-ngx/paperless-ngx` v2.20.10
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://paperless.ewatkins.dev`
- Backed by PostgreSQL (via `paperless-db-secret`) and Dragonfly as a Redis task queue
- Document storage via NFS from `caspian.local:/mnt/user/paperless`
- OCR configured for Dutch (`nld`)
- OIDC sign-in via Keycloak (`allauth.socialaccount.providers.openid_connect`)
- Consumer polls for new documents every 60 seconds with recursive subdirectory ingestion

## Links

- [Documentation](https://docs.paperless-ngx.com/)
- [GitHub Repository](https://github.com/paperless-ngx/paperless-ngx)
