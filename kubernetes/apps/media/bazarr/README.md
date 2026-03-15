# [Bazarr](https://www.bazarr.media/)

Bazarr automatically downloads and manages subtitles for the media library, working alongside Sonarr and Radarr to keep subtitle files in sync with new and existing content.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/home-operations/bazarr:1.5.6` | |
| URL | `https://bazarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `6767` | HTTP |
| Timezone | `America/Chicago` | |
| Config storage | `bazarr-config` PVC, 5Gi (`nfs-slow`) | Mounted at `/opt/bazarr/data` and `/config` |
| Media library | NFS `caspian.local:/mnt/user/arrdata` | Mounted at `/mnt/arrdata`; shared with all *arr apps |
| Run as user/group | `99:100` | |
| Memory limit | `1Gi` | |

## Links

- [Documentation](https://wiki.bazarr.media/)
- [GitHub Repository](https://github.com/morpheus65535/bazarr)
