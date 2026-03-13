# [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs)

The NFS CSI driver provisions PersistentVolumes backed by NFS shares on the `caspian.local` NAS. It is used for shared storage across multiple pods — primarily the media library and Kubernetes-managed application data.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Default server | `caspian.local` | The NAS hosting all NFS exports |
| `nfs-slow` StorageClass | `/mnt/user/kubernetes` | Kubernetes-managed PVC data; used for Loki, runner workspaces, and general shared PVCs |
| Mount options | `nfsvers=4.2`, `nconnect=16`, `soft`, `noatime` | `nconnect=16` parallelizes connections for better throughput; `soft` prevents hangs on NAS failures |
| `nfs-fast` StorageClass | (created separately) | Used by the actions-runner-controller for job workspace volumes |

## Links

- [Documentation](https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/docs)
- [GitHub Repository](https://github.com/kubernetes-csi/csi-driver-nfs)
