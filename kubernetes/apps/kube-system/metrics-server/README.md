# [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

Metrics Server collects CPU and memory usage from kubelets and exposes them via the Kubernetes Metrics API (`metrics.k8s.io`). It powers `kubectl top node`, `kubectl top pod`, and the Vertical Pod Autoscaler recommender.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Kubelet address type | `InternalIP` | Avoids hostname resolution issues on Talos nodes |
| Metric resolution | 15 seconds | How frequently usage is scraped from each kubelet |

## Links

- [Documentation](https://github.com/kubernetes-sigs/metrics-server#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server)
- [GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
