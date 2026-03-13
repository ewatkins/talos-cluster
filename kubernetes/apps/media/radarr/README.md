# [Radarr](https://radarr.video/)

Radarr is a movie collection manager for Usenet and BitTorrent users that monitors feeds for new releases, grabs them, sorts them, and renames them automatically.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `radarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/home-operations/radarr` v6.1.1.10317
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `radarr-config` PVC
- Media library mounted via NFS from `caspian.local:/mnt/user/arrdata`

## Links

- [Documentation](https://wiki.servarr.com/radarr)
- [GitHub Repository](https://github.com/Radarr/Radarr)
