# [Grafana](https://grafana.com/)

Operational dashboards for metrics and logs. Queries data from Prometheus (via Thanos) and Loki.

## Dashboards

Dashboards are provisioned automatically via ConfigMaps with the label `grafana_dashboard: "1"`. They can be added per-app or via shared components.

## Data Sources

| Source | Purpose |
| --- | --- |
| Thanos (via `thanos-query-frontend`) | Long-term metrics |
| Loki | Log aggregation |

## Links

- [Documentation](https://grafana.com/docs/grafana/latest/)
- [GitHub Repository](https://github.com/grafana/grafana)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
