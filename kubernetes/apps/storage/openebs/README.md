# [OpenEBS](https://openebs.io/)

OpenEBS provides the default `hostpath` PersistentVolume provisioner for the cluster. It enables fast, node-local storage for workloads that do not require shared access across nodes.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `openebs 4.4.0` from HelmRepository `openebs` | |
| Storage class | `openebs-hostpath` | Cluster default StorageClass (`isDefaultClass: true`) |
| Base path | `/var/openebs/local` | Host path where volumes are created on each node |
| Enabled engines | `localpv-provisioner` only | LVM, ZFS, and Mayastor engines are disabled |
| Volume snapshots | Disabled | `openebs-crds.csi.volumeSnapshots.enabled: false` |
| Bundled Loki | Disabled | `loki.enabled: false` |
| Bundled Alloy | Disabled | `alloy.enabled: false` |
| Bundled MinIO | Disabled | `minio.enabled: false` |
| Image registry | `quay.io/` | Overrides the default registry for the localpv image |

## Usage Notes

Because hostpath volumes are local to a single node, pods using `openebs-hostpath` PVCs are permanently scheduled on the node where their data was first created. Workloads using this StorageClass include Garage metadata, and any PVC that does not specify a StorageClass explicitly.

## Links

- [Documentation](https://openebs.io/docs/)
- [Helm Chart](https://github.com/openebs/openebs/tree/main/charts)
- [GitHub Repository](https://github.com/openebs/openebs)
