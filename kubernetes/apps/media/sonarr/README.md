# [Sonarr](https://sonarr.tv/)

Sonarr manages the TV series collection. It monitors configured indexers (via Prowlarr) for new episode releases, automatically grabs and sends them to a download client, then sorts and renames completed downloads into the media library.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/home-operations/sonarr:4.0.16.2946` | |
| URL | `https://sonarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `80` | HTTP |
| Instance name | `Sonarr` | |
| Theme | `dark` | |
| Auth method | `External` | Authentication handled upstream; disabled for local addresses |
| Update branch | `develop` | |
| DB logging | Disabled | |
| Timezone | `America/Chicago` | |
| Config PVC | `sonarr-config`, 10Gi (`nfs-slow`) | Mounted at `/var/lib/sonarr` and `/config` |
| Media library | NFS `storage.ewatkins.dev:/mnt/user/arrdata` | Mounted at `/mnt/arrdata`; shared with all *arr apps |
| Run as user/group | `99:100` | |
| Memory limit | `1Gi` | |

## Links

- [Documentation](https://wiki.servarr.com/sonarr)
- [GitHub Repository](https://github.com/Sonarr/Sonarr)
