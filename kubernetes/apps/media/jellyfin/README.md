# [Jellyfin](https://jellyfin.org/)

Jellyfin is the media server for this cluster, streaming movies, TV shows, and music from the NAS. It uses an Intel GPU for hardware-accelerated transcoding via the Kubernetes Dynamic Resource Allocation (DRA) API.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/jellyfin/jellyfin:10.11.6` | |
| URL | `https://jellyfin.ewatkins.dev` | Internal HTTPRoute and dedicated LoadBalancer IP (Cilium LB IPAM, `${JELLYFIN}`) |
| Port | `8096` | HTTP |
| Published server URL | `https://jellyfin.ewatkins.dev` | Used for client auto-discovery |
| GPU transcoding | Intel GPU via DRA `ResourceClaimTemplate` | `deviceClassName: gpu.intel.com`; requires the Intel GPU resource driver |
| Supplemental groups | `44`, `105`, `10000` | Required for Intel GPU device access |
| Transcode directory | `emptyDir` at `/transcode` | Ephemeral; cleared on pod restart |
| Config PVC | `jellyfin-config`, 5Gi (`nfs-slow`) | Mounted at `/etc/jellyfin` |
| Data PVC | `jellyfin-data`, 5Gi (`nfs-slow`) | Mounted at `/var/lib/jellyfin` |
| Cache PVC | `jellyfin-cache`, 5Gi (`nfs-fast`) | Mounted at `/var/cache/jellyfin` |
| Media library | NFS `caspian.local:/mnt/user/arrdata` | Mounted at `/mnt/arrdata`; shared with all *arr apps |
| Run as user/group | `99:100` | |
| Memory limit | `4Gi` | |

## Links

- [Documentation](https://jellyfin.org/docs/)
- [GitHub Repository](https://github.com/jellyfin/jellyfin)
