# [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs)

The NFS CSI driver provisions PersistentVolumes backed by NFS shares on the `caspian.local` NAS. It provides two StorageClasses for workloads that require shared or cross-node access to storage.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `csi-driver-nfs 4.13.1` via `oci://ghcr.io/home-operations/charts-mirror/csi-driver-nfs` | |
| Controller replicas | 1 | |
| NAS server | `caspian.local` | |

## StorageClasses

| StorageClass | NFS Share | Reclaim Policy | Notes |
| --- | --- | --- | --- |
| `nfs-slow` | `/mnt/user/kubernetes` | Delete | Created by the Helm chart; used for Garage data, and general shared PVCs |
| `nfs-fast` | `/mnt/user/kubernetes-fast` | Delete | Created separately via `storageclass.yaml`; supports `allowVolumeExpansion` |

Both StorageClasses use the same mount options:

| Mount Option | Value | Purpose |
| --- | --- | --- |
| `nfsvers` | `4.2` | NFSv4.2 protocol |
| `nconnect` | `16` | Parallelizes TCP connections for higher throughput |
| `hard` | — | Retries indefinitely on NAS failure (does not return errors to applications) |
| `timeo` | `600` | RPC timeout (tenths of a second) before retry |
| `retrans` | `5` | Number of retransmissions before reporting an error |
| `noatime` | — | Disables access-time updates to reduce write amplification |

Both classes use `volumeBindingMode: Immediate`.

## Links

- [Documentation](https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/docs)
- [GitHub Repository](https://github.com/kubernetes-csi/csi-driver-nfs)
