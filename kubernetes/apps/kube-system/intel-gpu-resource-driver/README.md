# [Intel GPU Resource Driver](https://github.com/intel/intel-resource-drivers-for-kubernetes)

The Intel GPU Resource Driver implements the Kubernetes Dynamic Resource Allocation (DRA) API for Intel GPUs. It enables workloads like Jellyfin to claim GPU resources for hardware-accelerated transcoding without relying on legacy device plugin APIs.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| CDI static path | `/var/cdi/static` | Container Device Interface definitions for known devices |
| CDI dynamic path | `/var/cdi/dynamic` | Runtime-generated CDI entries for allocated GPUs |

GPU access is requested by Jellyfin via a `ResourceClaim`. Node Feature Discovery labels nodes with Intel GPU capabilities, which the resource driver uses to advertise available devices to the scheduler.

## Links

- [Documentation](https://github.com/intel/intel-resource-drivers-for-kubernetes/tree/main/docs)
- [GitHub Repository](https://github.com/intel/intel-resource-drivers-for-kubernetes)
