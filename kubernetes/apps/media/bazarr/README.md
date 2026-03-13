# [Bazarr](https://www.bazarr.media/)

Bazarr is a companion application to Sonarr and Radarr that automatically downloads and manages subtitles for your media library.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `bazarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/home-operations/bazarr` v1.5.6
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `bazarr-config` PVC mounted at `/opt/bazarr/data` and `/config`
- Media library mounted via NFS from `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata`

## Links

- [Documentation](https://wiki.bazarr.media/)
- [GitHub Repository](https://github.com/morpheus65535/bazarr)
