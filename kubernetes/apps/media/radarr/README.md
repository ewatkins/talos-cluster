# [Radarr](https://radarr.video/)

Radarr manages the movie collection. It monitors configured indexers (via Prowlarr) for new releases, automatically grabs and sends them to a download client, then sorts and renames completed downloads into the media library.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/home-operations/radarr:6.1.1.10317` | |
| URL | `https://radarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `80` | HTTP |
| Instance name | `Radarr` | |
| Theme | `dark` | |
| Auth method | `External` | Authentication handled upstream; disabled for local addresses |
| Update branch | `develop` | |
| DB logging | Disabled | |
| Timezone | `America/Chicago` | |
| Config PVC | `radarr-config`, 10Gi (`nfs-slow`) | Mounted at `/var/lib/radarr` and `/config` |
| Media library | NFS `storage.ewatkins.dev:/mnt/user/arrdata` | Mounted at `/mnt/arrdata`; shared with all *arr apps |
| Run as user/group | `99:100` | |
| Memory limit | `1Gi` | |

## Links

- [Documentation](https://wiki.servarr.com/radarr)
- [GitHub Repository](https://github.com/Radarr/Radarr)
