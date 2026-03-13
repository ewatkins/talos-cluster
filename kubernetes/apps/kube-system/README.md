# kube-system

This namespace hosts core Kubernetes infrastructure components including networking (Cilium), DNS (CoreDNS), storage drivers, node feature detection, and cluster optimization tools.

## Apps

- [cilium](cilium/README.md) - eBPF-based CNI for pod networking, network policy, and Hubble observability
- [coredns](coredns/README.md) - Cluster DNS server
- [descheduler](descheduler/README.md) - Evicts pods to rebalance workloads across nodes
- [intel-gpu-resource-driver](intel-gpu-resource-driver/README.md) - Kubernetes resource driver for Intel GPUs
- [kubelet-csr-approver](kubelet-csr-approver/README.md) - Automatically approves kubelet certificate signing requests
- [metrics-server](metrics-server/README.md) - Provides resource usage metrics for the Kubernetes API
- [node-feature-discovery](node-feature-discovery/README.md) - Detects and labels hardware features on nodes
- [reloader](reloader/README.md) - Watches ConfigMaps and Secrets and triggers rolling restarts of dependent workloads
- [spegel](spegel/README.md) - Peer-to-peer container image distribution across cluster nodes
- [vpa](vpa/README.md) - Vertical Pod Autoscaler for recommending CPU and memory resource settings
