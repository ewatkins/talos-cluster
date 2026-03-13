# [Sonarr](https://sonarr.tv/)

Sonarr is a TV series collection manager for Usenet and BitTorrent users that monitors feeds for new episodes, grabs them, sorts them, and renames them automatically.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `sonarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/home-operations/sonarr` v4.0.16.2946
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `sonarr-config` PVC
- Media library mounted via NFS from `caspian.local:/mnt/user/arrdata`

## Links

- [Documentation](https://wiki.servarr.com/sonarr)
- [GitHub Repository](https://github.com/Sonarr/Sonarr)
