# kube-system

Core Kubernetes infrastructure including networking, DNS, storage drivers, node feature detection, and cluster optimization tools.

## Apps

| App | Description |
| --- | --- |
| [cilium](cilium/README.md) | eBPF-based CNI providing pod networking, network policy, and Hubble observability |
| [coredns](coredns/README.md) | Cluster DNS server for in-cluster service and pod name resolution |
| [descheduler](descheduler/README.md) | Evicts pods to rebalance workloads across nodes when scheduling constraints change |
| [intel-gpu-resource-driver](intel-gpu-resource-driver/README.md) | Dynamic Resource Allocation driver exposing Intel GPUs for hardware-accelerated transcoding |
| [kubelet-csr-approver](kubelet-csr-approver/README.md) | Automatically approves kubelet certificate signing requests for cluster nodes |
| [metrics-server](metrics-server/README.md) | Aggregates CPU and memory usage metrics for `kubectl top` and autoscaling pipelines |
| [node-feature-discovery](node-feature-discovery/README.md) | Detects and labels hardware features (PCI, USB, system) on each node |
| [reloader](reloader/README.md) | Triggers rolling restarts of workloads when referenced ConfigMaps or Secrets change |
| [spegel](spegel/README.md) | Peer-to-peer OCI image mirror that reduces external registry pull traffic |
| [vpa](vpa/README.md) | Vertical Pod Autoscaler recommender providing right-sizing suggestions via Goldilocks |
