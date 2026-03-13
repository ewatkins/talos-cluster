# [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/)

Promtail runs as a DaemonSet on every cluster node, tailing container log files and forwarding them to Loki with appropriate Kubernetes metadata labels (namespace, pod name, container name). It is the log collection agent for this cluster's observability stack.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Loki endpoint | `http://loki-headless.observability.svc.cluster.local:3100/loki/api/v1/push` | Direct push to the Loki headless service |

## Links

- [Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/promtail)
- [GitHub Repository](https://github.com/grafana/loki/tree/main/clients/pkg/promtail)
