# [Vertical Pod Autoscaler (VPA)](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

The Vertical Pod Autoscaler analyzes historical CPU and memory usage and produces recommendations for right-sizing container resource requests. In this cluster, only the recommender component is enabled — recommendations are surfaced via [Goldilocks](../../observability/goldilocks/README.md) rather than applied automatically.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Components enabled | `recommender` only | `updater` and `admissionController` are disabled — VPA does not automatically mutate pods |
| Metrics source | Thanos Query Frontend | `http://thanos-query-frontend.observability.svc.cluster.local:10902` — gives the recommender access to long-term metrics history |

Keeping the updater disabled means recommendations are advisory. Use the Goldilocks dashboard to review and manually apply resource request changes.

## Links

- [Documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#readme)
- [Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/vpa)
- [GitHub Repository](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
