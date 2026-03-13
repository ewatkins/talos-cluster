# [Intel GPU Resource Driver](https://github.com/intel/intel-resource-drivers-for-kubernetes)

The Intel GPU Resource Driver implements the Kubernetes Dynamic Resource Allocation (DRA) API for Intel GPUs, enabling workloads such as Jellyfin to request and use GPU resources for hardware-accelerated transcoding.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `intel-gpu-resource-driver` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `intel-gpu-resource-driver-chart` v0.9.1 from `oci://ghcr.io/intel/intel-resource-drivers-for-kubernetes`
- CDI paths configured: static at `/var/cdi/static`, dynamic at `/var/cdi/dynamic`

## Links

- [Documentation](https://github.com/intel/intel-resource-drivers-for-kubernetes/tree/main/docs)
- [GitHub Repository](https://github.com/intel/intel-resource-drivers-for-kubernetes)
