# [OpenEBS](https://openebs.io/)

OpenEBS provides the default `hostpath` PersistentVolume provisioner for the cluster. It enables fast, node-local storage for workloads that do not require shared access across nodes — primarily the observability stack and machine learning model caches.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Storage class | `openebs-hostpath` (default) | Used when no StorageClass is specified in a PVC |
| Base path | `/var/openebs/local` | Host path where volumes are created on each node |
| Enabled engines | `localpv-provisioner` only | LVM, ZFS, and Mayastor storage engines are disabled to minimize resource usage |

## Consumers

Workloads using OpenEBS hostpath storage include Loki, Thanos Store Gateway, Thanos Compactor, and the Immich machine learning model cache.

> Because hostpath volumes are local to a single node, pods using OpenEBS PVCs will always be scheduled on the same node their data was created on. Take this into account when planning node maintenance.

## Links

- [Documentation](https://openebs.io/docs/)
- [Helm Chart](https://github.com/openebs/openebs/tree/main/charts)
- [GitHub Repository](https://github.com/openebs/openebs)
