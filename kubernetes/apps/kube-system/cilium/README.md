# [Cilium](https://cilium.io/)

Cilium is the eBPF-based CNI for this cluster. It replaces kube-proxy entirely, handles pod networking in native routing mode, and provides L2 load balancer IP announcements. Hubble is enabled for real-time network flow visibility and Prometheus metrics. Core networking settings (kube-proxy replacement, BPF, IPAM) are injected via the `cilium-helm-values` ConfigMap generated from `talos/talconfig.yaml` and `kubernetes/apps/kube-system/cilium/app/helm-values.yaml`.

## Chart

| Field | Value |
| --- | --- |
| Chart | `cilium/cilium` |
| Version | `1.19.1` |
| Source | HelmRepository `cilium` in `flux-system` |

## Flux Kustomizations

Two Flux Kustomizations manage Cilium:

| Kustomization | Path | Prune | Notes |
| --- | --- | --- | --- |
| `cilium` | `cilium/app` | false | Installs the HelmRelease; never pruned |
| `cilium-config` | `cilium/config` | false | Applies L2 announcement policy and IP pool; depends on `cilium` |

## Networking configuration (helm-values.yaml)

| Setting | Value |
| --- | --- |
| Routing mode | `native` |
| IPAM mode | `kubernetes` |
| IPv4 native routing CIDR | `10.69.0.0/16` |
| kube-proxy replacement | `true` |
| kube-proxy healthz bind address | `0.0.0.0:10256` |
| BPF masquerade | `true` |
| Auto direct node routes | `true` |
| Endpoint routes | enabled |
| L2 announcements | enabled |
| Load balancer algorithm | `maglev` |
| Load balancer mode | `snat` |
| Local redirect policy | enabled |
| BGP control plane | enabled |
| Envoy | disabled |
| Cluster ID | `1` |
| Cluster name | `great-lakes` |
| k8s API server | `127.0.0.1:7445` (local Talos proxy) |
| Operator replicas | `2` |
| cgroup automount | disabled |
| cgroup hostRoot | `/sys/fs/cgroup` |
| CNI exclusive | `false` |

## Hubble configuration (helmrelease.yaml)

| Setting | Value |
| --- | --- |
| Hubble | enabled |
| Hubble relay | enabled, `rollOutPods: true` |
| Hubble UI | enabled, `rollOutPods: true` |
| Hubble UI ingress | `hubble.ewatkins.dev` via `internal` ingress class |
| Hubble UI DNS target | `internal.ewatkins.dev` |
| Hubble metrics | `dns:query`, `drop`, `tcp`, `flow`, `port-distribution`, `icmp`, `http` |
| Hubble metrics ServiceMonitor | enabled |
| Hubble relay ServiceMonitor | enabled |
| Grafana dashboards | enabled, folder `Cilium` |

## Prometheus metrics

| Component | ServiceMonitor |
| --- | --- |
| Cilium agent | enabled |
| Cilium operator | enabled |
| Hubble relay | enabled |
| Hubble metrics endpoint | enabled |

## L2 announcement policy (cilium-l2.yaml)

`CiliumL2AnnouncementPolicy` `l2-policy` selects all Linux nodes and announces load balancer IPs.

`CiliumLoadBalancerIPPool` `l2-pool` includes four address blocks populated via Flux variable substitution:

| Block | Variable |
| --- | --- |
| kube-vip VIP | `${KUBE_VIP}/32` |
| Internal ingress IP | `${INTERNAL}/32` |
| External ingress IP | `${EXTERNAL}/32` |
| Node CIDR range | `${NODE_CIDR_START}` – `${NODE_CIDR_END}` |

## Links

- [Documentation](https://docs.cilium.io/)
- [Helm Chart](https://github.com/cilium/cilium/tree/main/install/kubernetes/cilium)
- [GitHub Repository](https://github.com/cilium/cilium)
- [Hubble](https://github.com/cilium/hubble)
