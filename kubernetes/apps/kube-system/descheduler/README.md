# [Descheduler](https://github.com/kubernetes-sigs/descheduler)

The Descheduler periodically evicts pods that violate scheduling constraints after their initial placement, allowing the Kubernetes scheduler to re-place them on more appropriate nodes. It runs as a Deployment (rather than a CronJob) with leader election so one active instance is always running.

## Chart

| Field | Value |
| --- | --- |
| Chart | `descheduler/descheduler` |
| Version | `0.35.1` |
| Source | HelmRepository `descheduler` in `flux-system` |

## Deployment settings

| Setting | Value |
| --- | --- |
| Kind | `Deployment` |
| Replicas | `2` |
| Leader election | enabled |
| Policy API version | `descheduler/v1alpha2` |
| Metrics Service | enabled |
| ServiceMonitor | enabled |

## Evictor settings (DefaultEvictor)

| Setting | Value |
| --- | --- |
| `evictFailedBarePods` | `true` — evict failed pods with no owner |
| `evictLocalStoragePods` | `true` — evict pods using local storage |
| `evictSystemCriticalPods` | `true` — evict system-critical pods if they violate constraints |
| `nodeFit` | `true` — only evict if a suitable alternative node exists |

## Active plugins

| Plugin | Phase | What it fixes |
| --- | --- | --- |
| `RemovePodsViolatingInterPodAntiAffinity` | deschedule | Evicts pods that now violate anti-affinity rules |
| `RemovePodsViolatingNodeAffinity` | deschedule | Evicts pods whose `requiredDuringSchedulingIgnoredDuringExecution` node affinity is no longer satisfied |
| `RemovePodsViolatingNodeTaints` | deschedule | Evicts pods running on nodes they should no longer tolerate |
| `RemovePodsViolatingTopologySpreadConstraint` | balance | Rebalances pods when `DoNotSchedule` or `ScheduleAnyway` spread constraints are violated |

## Links

- [Documentation](https://github.com/kubernetes-sigs/descheduler#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/descheduler/tree/master/charts/descheduler)
- [GitHub Repository](https://github.com/kubernetes-sigs/descheduler)
