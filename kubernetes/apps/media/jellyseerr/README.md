# [Jellyseerr](https://github.com/fallenbagel/jellyseerr)

Jellyseerr is a media request management and discovery tool for Jellyfin, allowing users to browse and request movies and TV shows that are then automatically fulfilled by Radarr and Sonarr.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `jellyseerr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/fallenbagel/jellyseerr` v2.7.3
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `jellyseerr-config` PVC and cache in `jellyseerr-cache` PVC

## Links

- [Documentation](https://github.com/fallenbagel/jellyseerr#readme)
- [GitHub Repository](https://github.com/fallenbagel/jellyseerr)
