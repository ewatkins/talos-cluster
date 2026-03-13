# [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs)

The NFS CSI driver allows Kubernetes to provision PersistentVolumes backed by NFS shares, used for shared media storage and Kubernetes-managed volumes on the `caspian.local` NAS.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `csi-driver-nfs` |
| `StorageClass` | `nfs-slow` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `csi-driver-nfs` v4.13.1 from `oci://ghcr.io/home-operations/charts-mirror/csi-driver-nfs`
- Creates a default `nfs-slow` StorageClass pointing to `caspian.local:/mnt/user/kubernetes`
- NFS mount options: NFSv4.2, nconnect=16, soft, noatime
- A second StorageClass (`nfs-fast`) is used by the actions runner but must be created separately

## Links

- [Documentation](https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/docs)
- [GitHub Repository](https://github.com/kubernetes-csi/csi-driver-nfs)
