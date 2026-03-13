# [Vertical Pod Autoscaler (VPA)](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

The Vertical Pod Autoscaler (VPA) automatically recommends CPU and memory resource requests for containers based on historical usage data, helping right-size workloads across the cluster.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `vpa` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `vpa` v4.10.2 from the `fairwinds` Helm repository
- Only the `recommender` component is enabled; `updater` and `admissionController` are disabled
- Recommender uses Thanos Query Frontend as the Prometheus backend (`http://thanos-query-frontend.observability.svc.cluster.local:10902`)
- VPA recommendations can be read by Goldilocks to surface them in the UI

## Links

- [Documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#readme)
- [Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/vpa)
- [GitHub Repository](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
