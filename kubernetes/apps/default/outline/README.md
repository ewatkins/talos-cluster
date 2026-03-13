# [Outline](https://www.getoutline.com/)

Outline is an open-source knowledge base and team wiki. It provides a modern, collaborative document editor with support for OIDC authentication.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `outline` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `outlinewiki/outline` v1.5.0
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://notes.ewatkins.dev`
- Backed by PostgreSQL (via `outline-db` secret) and Dragonfly for Redis-compatible caching
- Authentication via Keycloak OIDC (`OIDC_DISPLAY_NAME: Keycloak`)
- Object storage via Minio (`s3.ewatkins.dev`)

## Links

- [Documentation](https://docs.getoutline.com/)
- [GitHub Repository](https://github.com/outline/outline)
