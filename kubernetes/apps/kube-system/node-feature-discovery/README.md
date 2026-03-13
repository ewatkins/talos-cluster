# [Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery)

Node Feature Discovery (NFD) detects hardware features on each cluster node and exposes them as Kubernetes node labels, enabling workloads to target nodes with specific capabilities such as Intel GPUs or connected USB devices.

## Configuration

| Source | What it discovers |
| --- | --- |
| `pci` | PCI devices including Intel GPU presence |
| `usb` | Connected USB devices |
| `system` | OS-level features (kernel version, OS, architecture) |

NFD labels are used by the Intel GPU Resource Driver and can be used in node affinity rules to target specific hardware.

## Links

- [Documentation](https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/)
- [Helm Chart](https://github.com/kubernetes-sigs/node-feature-discovery/tree/master/deployment/helm)
- [GitHub Repository](https://github.com/kubernetes-sigs/node-feature-discovery)
