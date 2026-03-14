# [Grafana](https://grafana.com/)

Operational dashboards for metrics, logs, and alerts. Runs 2 replicas and authenticates via Keycloak generic OAuth.

## Data Sources

| Source | URL | Purpose |
| --- | --- | --- |
| Prometheus | `kps-prometheus.observability.svc.cluster.local:9090` | Cluster metrics (2d local retention) |
| Loki | `loki-headless.observability.svc.cluster.local:3100` | Log aggregation |
| Alertmanager | `alertmanager-operated.observability.svc.cluster.local:9093` | Active alert state |

## Dashboard Folders

Dashboards are provisioned automatically from the HelmRelease `values.dashboards` block and organized into folders:

| Folder | Contents |
| --- | --- |
| `default` | Cloudflare tunnels, external-dns, MinIO, node-exporter, Spegel, cert-manager, external-secrets, goldilocks, etc. |
| `flux` | Flux cluster health and control plane |
| `kubernetes` | API server, CoreDNS, global view, namespaces, nodes, PVCs, volumes |
| `prometheus` | Prometheus internals |
| `thanos` | Thanos component dashboards |

## Links

- [Documentation](https://grafana.com/docs/grafana/latest/)
- [GitHub Repository](https://github.com/grafana/grafana)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
