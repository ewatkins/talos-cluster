# [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

Metrics Server is a scalable, efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines. It collects CPU and memory usage from kubelets and exposes them via the Kubernetes Metrics API.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `metrics-server` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `metrics-server` v3.13.0 from the `metrics-server` Helm repository
- Configured to prefer `InternalIP` for kubelet address resolution
- Metric resolution interval: 15 seconds
- Prometheus ServiceMonitor enabled

## Links

- [Documentation](https://github.com/kubernetes-sigs/metrics-server#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server)
- [GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
