# [CoreDNS](https://coredns.io/)

CoreDNS is the cluster DNS server, resolving `cluster.local` service and pod names within the cluster. It runs exclusively on control-plane nodes with a topology spread constraint ensuring no two replicas land on the same host.

## Chart

| Field | Value |
| --- | --- |
| Chart | `coredns/coredns` |
| Version | `1.45.2` |
| Source | HelmRepository `coredns` in `flux-system` |

## Configuration

Values are sourced from the `coredns-helm-values` ConfigMap, generated from `kubernetes/apps/kube-system/coredns/app/helm-values.yaml` by Kustomize's configMapGenerator. The HelmRelease itself defines no inline values — all settings are in the ConfigMap.

| Setting | Value |
| --- | --- |
| Replicas | `3` |
| Service name | `kube-dns` |
| Cluster IP | `10.96.0.10` |
| Full name override | `coredns` |
| App label override | `kube-dns` |

## Corefile plugins

| Plugin | Configuration |
| --- | --- |
| `errors` | Log all errors |
| `health` | Liveness probe with `lameduck 5s` |
| `ready` | Readiness probe |
| `log` | Log `error` class queries |
| `prometheus` | Metrics on `0.0.0.0:9153` |
| `kubernetes` | Authoritative for `cluster.local in-addr.arpa ip6.arpa`; `pods insecure`; fallthrough for reverse zones |
| `forward` | Forward external queries to `/etc/resolv.conf` (node resolver) |
| `cache` | 30-second TTL |
| `loop` | Loop detection |
| `reload` | Hot-reload Corefile on change |
| `loadbalance` | Round-robin DNS load balancing |

## Scheduling

| Constraint | Value |
| --- | --- |
| Node affinity | Required: `node-role.kubernetes.io/control-plane` exists |
| Tolerations | `CriticalAddonsOnly`, `node-role.kubernetes.io/control-plane:NoSchedule` |
| Topology spread | `maxSkew: 1` per `kubernetes.io/hostname`; `DoNotSchedule` when unsatisfiable |

## Links

- [Documentation](https://coredns.io/manual/toc/)
- [Helm Chart](https://github.com/coredns/helm)
- [GitHub Repository](https://github.com/coredns/coredns)
