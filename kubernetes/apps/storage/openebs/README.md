# [OpenEBS](https://openebs.io/)

OpenEBS provides the default local `hostpath` PersistentVolume provisioner for the cluster. It enables fast, node-local storage for workloads that do not require shared access across nodes.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `openebs` |
| `StorageClass` | `openebs-hostpath` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `openebs` v4.4.0 from the `openebs` Helm repository
- Only the `localpv-provisioner` is enabled; LVM, ZFS, and Mayastor engines are disabled
- `openebs-hostpath` is the default StorageClass with base path `/var/openebs/local`
- Used by Loki, Thanos, machine learning caches, and other workloads requiring fast local storage

## Links

- [Documentation](https://openebs.io/docs/)
- [Helm Chart](https://github.com/openebs/openebs/tree/main/charts)
- [GitHub Repository](https://github.com/openebs/openebs)
