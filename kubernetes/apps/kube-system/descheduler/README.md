# [Descheduler](https://github.com/kubernetes-sigs/descheduler)

The Descheduler evicts pods from nodes so they can be rescheduled onto more appropriate nodes, helping maintain balance across the cluster when scheduling constraints change after initial placement.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `descheduler` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `descheduler` v0.35.1 from the `descheduler` Helm repository
- Runs as a `Deployment` with 2 replicas and leader election enabled
- Active plugins: `RemovePodsViolatingInterPodAntiAffinity`, `RemovePodsViolatingNodeAffinity`, `RemovePodsViolatingNodeTaints`, `RemovePodsViolatingTopologySpreadConstraint`
- Prometheus ServiceMonitor enabled

## Links

- [Documentation](https://github.com/kubernetes-sigs/descheduler#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/descheduler/tree/master/charts/descheduler)
- [GitHub Repository](https://github.com/kubernetes-sigs/descheduler)
