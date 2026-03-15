# [Jellyseerr](https://github.com/fallenbagel/jellyseerr)

Jellyseerr is the media request portal for this cluster. Users browse and request movies and TV shows through its interface; approved requests are automatically forwarded to Radarr or Sonarr for acquisition and delivery into Jellyfin.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/fallenbagel/jellyseerr:2.7.3` | |
| URLs | `https://requests.ewatkins.dev`, `https://media.ewatkins.dev` | Internal gateway only; both hostnames resolve to the same service |
| Port | `8080` | HTTP |
| Log level | `info` | |
| Config PVC | `jellyseerr-config`, 5Gi (`nfs-slow`) | Mounted at `/app/config`; persists request history, users, and integrations |
| Cache PVC | `jellyseerr-cache`, 15Gi (`nfs-fast`) | Mounted at `/app/config/cache`; caches poster images and external metadata |
| Run as user/group | `99:100` | |
| Memory limit | `2Gi` | |

## Links

- [Documentation](https://github.com/fallenbagel/jellyseerr#readme)
- [GitHub Repository](https://github.com/fallenbagel/jellyseerr)
