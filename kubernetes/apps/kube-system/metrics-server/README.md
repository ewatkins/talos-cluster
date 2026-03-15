# [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

Metrics Server collects CPU and memory usage from kubelets and exposes them via the Kubernetes Metrics API (`metrics.k8s.io/v1beta1`). It is a prerequisite for `kubectl top node`, `kubectl top pod`, and the VPA recommender.

## Chart

| Field | Value |
| --- | --- |
| Chart | `metrics-server/metrics-server` |
| Version | `3.13.0` |
| Source | HelmRepository `metrics-server` in `flux-system` |

## Configuration

| Setting | Value |
| --- | --- |
| `--kubelet-preferred-address-types` | `InternalIP,ExternalIP,Hostname` |
| `--kubelet-use-node-status-port` | enabled |
| `--metric-resolution` | `15s` |
| Metrics endpoint | enabled |
| ServiceMonitor | enabled |

`InternalIP` is listed first to avoid hostname resolution failures on Talos nodes. `--kubelet-use-node-status-port` directs metrics-server to use the port advertised in the Node status rather than a hardcoded default.

## Links

- [Documentation](https://github.com/kubernetes-sigs/metrics-server#readme)
- [Helm Chart](https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server)
- [GitHub Repository](https://github.com/kubernetes-sigs/metrics-server)
