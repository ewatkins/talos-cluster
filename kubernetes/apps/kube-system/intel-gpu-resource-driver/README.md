# [Intel GPU Resource Driver](https://github.com/intel/intel-resource-drivers-for-kubernetes)

The Intel GPU Resource Driver implements the Kubernetes Dynamic Resource Allocation (DRA) API for Intel integrated GPUs. It advertises GPU devices to the scheduler and provisions them into pods via Container Device Interface (CDI), enabling hardware-accelerated workloads such as video transcoding in Jellyfin.

## Chart

| Field | Value |
| --- | --- |
| Chart | `oci://ghcr.io/intel/intel-resource-drivers-for-kubernetes/intel-gpu-resource-driver-chart` |
| Version | `0.9.1` |
| Source | OCIRepository `intel-gpu-resource-driver` in `kube-system` |
| Pull interval | `15m` |

The HelmRelease references the OCIRepository directly (`chartRef`) rather than a HelmRepository. The chart is pulled as a `application/vnd.cncf.helm.chart.content.v1.tar+gzip` layer.

## Configuration

| Setting | Value |
| --- | --- |
| CDI static path | `/var/cdi/static` |
| CDI dynamic path | `/var/cdi/dynamic` |

- **Static path**: pre-defined CDI device definitions for known hardware.
- **Dynamic path**: runtime-generated CDI entries created when a GPU is allocated to a pod.

## Integration

Node Feature Discovery labels nodes with detected PCI devices (including Intel GPU presence). The resource driver reads these labels to determine which nodes have eligible GPUs and advertises `ResourceSlice` objects accordingly. Workloads request a GPU by creating a `ResourceClaim` referencing the Intel GPU resource class.

## Links

- [Documentation](https://github.com/intel/intel-resource-drivers-for-kubernetes/tree/main/docs)
- [GitHub Repository](https://github.com/intel/intel-resource-drivers-for-kubernetes)
- [CDI Specification](https://github.com/cncf-tags/container-device-interface)
- [Kubernetes DRA](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/)
