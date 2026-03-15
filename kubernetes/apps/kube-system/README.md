# kube-system

Core Kubernetes infrastructure for the `great-lakes` cluster. This namespace contains the CNI, cluster DNS, node-level drivers, certificate management, and workload optimization tooling. Flux alerts for all HelmRelease errors in this namespace are forwarded to Alertmanager. Goldilocks VPA recommendations are enabled on the namespace.

## Apps

| App | Chart Version | Description |
| --- | --- | --- |
| [cilium](cilium/README.md) | 1.19.1 | eBPF-based CNI providing pod networking, kube-proxy replacement, L2 load balancer announcements, and Hubble observability |
| [coredns](coredns/README.md) | 1.45.2 | Cluster DNS server pinned to control-plane nodes, resolving `cluster.local` and forwarding external queries |
| [descheduler](descheduler/README.md) | 0.35.1 | Evicts pods that violate scheduling constraints after initial placement to allow rescheduling |
| [intel-gpu-resource-driver](intel-gpu-resource-driver/README.md) | 0.9.1 | DRA driver exposing Intel GPUs for hardware-accelerated workloads via the Kubernetes DRA API |
| [kubelet-csr-approver](kubelet-csr-approver/README.md) | 1.2.13 | Automatically approves kubelet CSRs for the five cluster nodes plus `tahoe` |
| [metrics-server](metrics-server/README.md) | 3.13.0 | Aggregates CPU and memory usage metrics for `kubectl top` and the VPA recommender |
| [node-feature-discovery](node-feature-discovery/README.md) | 0.18.3 | Labels nodes with detected hardware features (PCI, USB, system) |
| [reloader](reloader/README.md) | 2.2.7 | Triggers rolling restarts when referenced ConfigMaps or Secrets change |
| [spegel](spegel/README.md) | 0.6.0 | Peer-to-peer OCI image mirror that reduces external registry pull traffic |
| [vpa](vpa/README.md) | 4.10.2 | VPA recommender (advisory only) backed by Thanos long-term metrics |

## Namespace configuration

| Setting | Value |
| --- | --- |
| Flux prune | disabled (annotation `kustomize.toolkit.fluxcd.io/prune: disabled`) |
| Goldilocks | enabled (`goldilocks.fairwinds.com/enabled: "true"`) |
| Flux alert sink | Alertmanager at `alertmanager-operated.observability.svc.cluster.local:9093` |
| Alert severity | `error` — covers all HelmRelease failures, excluding transient DNS/network timeouts |
