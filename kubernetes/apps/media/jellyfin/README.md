# [Jellyfin](https://jellyfin.org/)

Jellyfin is the media server for this cluster, streaming movies, TV shows, and music from the NAS. It uses an Intel GPU for hardware-accelerated transcoding via the Kubernetes Dynamic Resource Allocation (DRA) API.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://jellyfin.ewatkins.dev` | External access via dedicated LoadBalancer IP |
| GPU transcoding | Intel GPU via DRA `ResourceClaim` | Hardware-accelerated video transcoding using the Intel GPU resource driver |
| Media library | NFS `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata` | Shared NFS mount used by all *arr applications |
| Config PVC | `jellyfin-config` | Jellyfin server settings and database |
| Data PVC | `jellyfin-data` | Metadata, artwork, and transcoding cache |
| Cache PVC | `jellyfin-cache` | Temporary transcoding and image cache |

## Links

- [Documentation](https://jellyfin.org/docs/)
- [GitHub Repository](https://github.com/jellyfin/jellyfin)
