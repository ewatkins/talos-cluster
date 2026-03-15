# [Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery)

Node Feature Discovery (NFD) runs a worker DaemonSet on every node to detect hardware capabilities and expose them as Kubernetes node labels. These labels are consumed by the Intel GPU Resource Driver and can be used in node affinity rules to target specific hardware.

## Chart

| Field | Value |
| --- | --- |
| Chart | `node-feature-discovery/node-feature-discovery` |
| Version | `0.18.3` |
| Source | HelmRepository `node-feature-discovery` in `flux-system` |
| CRDs | `CreateReplace` on install and upgrade |

## Flux Kustomizations

| Kustomization | Path | Depends on |
| --- | --- | --- |
| `node-feature-discovery` | `node-feature-discovery/app` | — |
| `node-feature-discovery-rules` | `node-feature-discovery/rules` | `node-feature-discovery` |

The `rules/` directory currently contains no `NodeFeatureRule` resources (placeholder for future GPU rules).

## Worker sources

| Source | What it discovers |
| --- | --- |
| `pci` | PCI devices including Intel integrated GPU presence |
| `system` | OS-level features (kernel version, OS release, CPU architecture) |
| `usb` | Connected USB devices |

## Observability

| Setting | Value |
| --- | --- |
| Prometheus metrics | enabled |

## Links

- [Documentation](https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/)
- [Helm Chart](https://github.com/kubernetes-sigs/node-feature-discovery/tree/master/deployment/helm)
- [GitHub Repository](https://github.com/kubernetes-sigs/node-feature-discovery)
