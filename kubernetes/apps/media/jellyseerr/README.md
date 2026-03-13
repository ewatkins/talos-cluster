# [Jellyseerr](https://github.com/fallenbagel/jellyseerr)

Jellyseerr is the media request portal for this cluster. Users browse and request movies and TV shows through its interface, and approved requests are automatically sent to Radarr or Sonarr for acquisition and delivery into Jellyfin.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `jellyseerr-config` PVC | Persists request history, user settings, and integrations |
| Cache storage | `jellyseerr-cache` PVC | Caches poster images and metadata fetched from external sources |

## Links

- [Documentation](https://github.com/fallenbagel/jellyseerr#readme)
- [GitHub Repository](https://github.com/fallenbagel/jellyseerr)
