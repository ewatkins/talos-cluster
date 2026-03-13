# [Prowlarr](https://prowlarr.com/)

Prowlarr is an indexer manager and proxy for the *arr stack. It integrates with Sonarr and Radarr to provide unified indexer management without per-application configuration.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `prowlarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/home-operations/prowlarr` v2.3.3.5296
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `prowlarr-config` PVC

## Links

- [Documentation](https://wiki.servarr.com/prowlarr)
- [GitHub Repository](https://github.com/Prowlarr/Prowlarr)
