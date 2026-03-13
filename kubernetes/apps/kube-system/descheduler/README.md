# [Descheduler](https://github.com/kubernetes-sigs/descheduler)

The Descheduler evicts pods that violate scheduling constraints after initial placement, allowing the Kubernetes scheduler to place them on more appropriate nodes. This is particularly useful when nodes are added or when affinity rules change after pods are already running.

## Configuration

| Plugin | What it fixes |
| --- | --- |
| `RemovePodsViolatingInterPodAntiAffinity` | Evicts pods that violate anti-affinity rules that arose after initial scheduling |
| `RemovePodsViolatingNodeAffinity` | Evicts pods whose node affinity rules are no longer satisfied |
| `RemovePodsViolatingNodeTaints` | Evicts pods running on nodes they should no longer tolerate |
| `RemovePodsViolatingTopologySpreadConstraint` | Rebalances pods across zones when spread constraints are violated |

The descheduler runs as a 2-replica `Deployment` with leader election — only one instance is active at a time, but the second provides fast failover.

## Links

- [Documentation](https://github.com/kubernetes-sigs/descheduler#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/descheduler/tree/master/charts/descheduler)
- [GitHub Repository](https://github.com/kubernetes-sigs/descheduler)
