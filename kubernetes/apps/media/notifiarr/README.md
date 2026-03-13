# [Notifiarr](https://notifiarr.com/)

Notifiarr is a notification aggregation client that consolidates alerts and events from Sonarr, Radarr, Plex, Jellyfin, and other *arr applications and forwards them to Discord, email, and other notification services.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `notifiarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/notifiarr/notifiarr` v0.9.5
- Deployed via `bjw-s/app-template` (OCI)
- Config stored in `notifiarr-config` PVC
- Media library mounted via NFS from `caspian.local:/mnt/user/arrdata`

## Links

- [Documentation](https://notifiarr.wiki/)
- [GitHub Repository](https://github.com/Notifiarr/notifiarr)
