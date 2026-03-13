# [Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery)

Node Feature Discovery (NFD) detects hardware features and system configuration on each cluster node and exposes them as Kubernetes node labels, enabling workloads to be scheduled on nodes with specific capabilities (e.g., GPU, USB devices).

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `node-feature-discovery` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `node-feature-discovery` v0.18.3 from the `node-feature-discovery` Helm repository
- Worker sources enabled: `pci`, `system`, `usb`
- Prometheus metrics enabled

## Links

- [Documentation](https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/)
- [Helm Chart](https://github.com/kubernetes-sigs/node-feature-discovery/tree/master/deployment/helm)
- [GitHub Repository](https://github.com/kubernetes-sigs/node-feature-discovery)
