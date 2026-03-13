# [Reloader](https://github.com/stakater/Reloader)

Reloader watches Kubernetes `ConfigMap` and `Secret` resources for changes and automatically triggers rolling restarts of `Deployment`, `DaemonSet`, and `StatefulSet` workloads that reference them.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `reloader` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `reloader` v2.2.7 from the `stakater` Helm repository
- Restarts are triggered by adding the annotation `reloader.stakater.com/auto: "true"` to workloads
- Prometheus PodMonitor enabled

## Links

- [Documentation](https://github.com/stakater/Reloader#readme)
- [Helm Chart](https://github.com/stakater/Reloader/tree/master/deployments/kubernetes/chart/reloader)
- [GitHub Repository](https://github.com/stakater/Reloader)
