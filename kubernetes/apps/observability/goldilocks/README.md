# [Goldilocks](https://github.com/FairwindsOps/goldilocks)

Get resource requests "just right." Goldilocks watches running workloads and uses the Vertical Pod Autoscaler (VPA) to suggest appropriate CPU and memory requests and limits.

## Enabling a Namespace

Add the following label to any namespace you want Goldilocks to analyze:

```yaml
metadata:
  labels:
    goldilocks.fairwinds.com/enabled: "true"
```

## Resource Limits Guidance

CPU limits can cause throttling even under low utilization. See [this reference](https://github.com/robusta-dev/alert-explanations/wiki/CPUThrottlingHigh-(Prometheus-Alert)#why-cpu-throttling-can-occur-despite-low-cpu-usage-permalink) for details. Setting CPU limits does not affect other containers — other pods are still guaranteed the CPU they **request**.

General recommendation: set CPU _requests_, consider omitting CPU _limits_, and always set memory limits.

## Links

- [Documentation](https://goldilocks.docs.fairwinds.com/)
- [GitHub Repository](https://github.com/FairwindsOps/goldilocks)
- [Helm Chart](https://github.com/FairwindsOps/charts/tree/master/stable/goldilocks)
