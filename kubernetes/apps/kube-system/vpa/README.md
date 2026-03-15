# [Vertical Pod Autoscaler (VPA)](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

The Vertical Pod Autoscaler analyzes container resource usage and produces right-sizing recommendations for CPU and memory requests. Only the recommender component is deployed — the updater and admission controller are disabled, so VPA never automatically mutates pods. Recommendations are surfaced through the [Goldilocks](../../observability/goldilocks/README.md) dashboard.

## Chart

| Field | Value |
| --- | --- |
| Chart | `fairwinds/vpa` |
| Version | `4.10.2` |
| Source | HelmRepository `fairwinds` in `flux-system` |
| Sync interval | `15m` |

## Components

| Component | Enabled | Notes |
| --- | --- | --- |
| `recommender` | yes | Analyses usage history and produces `VPA` object recommendations |
| `updater` | no | Would evict pods to apply recommendations — disabled |
| `admissionController` | no | Would mutate new pod specs — disabled |

## Recommender configuration

| Setting | Value |
| --- | --- |
| Image | `registry.k8s.io/autoscaling/vpa-recommender:1.6.0` |
| `--storage` | `prometheus` |
| `--prometheus-address` | `http://thanos-query-frontend.observability.svc.cluster.local:10902` |
| CPU request | `23m` |
| Memory request / limit | `105Mi` |

Using `storage: prometheus` backed by Thanos Query Frontend gives the recommender access to long-term historical metrics beyond the default in-memory window.

## Other settings

| Setting | Value |
| --- | --- |
| Reloader annotation | `reloader.stakater.com/search: "true"` — triggers rolling restart when referenced secrets change |

## Links

- [Documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#readme)
- [Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/vpa)
- [GitHub Repository](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Goldilocks](https://github.com/FairwindsOps/goldilocks)
