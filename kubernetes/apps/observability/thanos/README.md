# [Thanos](https://thanos.io/)

Thanos extends the kube-prometheus-stack Prometheus instance with long-term metric storage and a global query layer. Prometheus remote-writes metrics into Thanos, which compacts and stores them in Minio. Grafana queries Thanos Query Frontend rather than Prometheus directly, giving access to the full historical metric range.

## Configuration

| Component | Replicas | Purpose |
| --- | --- | --- |
| `query` | 2 | Federated query layer across all stores |
| `queryFrontend` | 2 | Query caching and sharding for Grafana |
| `rule` | 2 | Prometheus-compatible recording and alerting rules |
| `storeGateway` | 1 | Serves historical metrics from object storage |
| `compact` | 1 | Downsamples and compacts stored metric blocks |

| Setting | Value | Notes |
| --- | --- | --- |
| Object store | Minio bucket `thanos` at `minio.storage.svc.cluster.local:9000` | Long-term metric storage |
| Retention raw | 14 days | Full-resolution data |
| Retention 5m | 30 days | 5-minute downsampled data |
| Retention 1h | 60 days | 1-hour downsampled data |
| Alertmanager | Integrated | Routes `PrometheusDown` alerts via Alertmanager |

## Links

- [Documentation](https://thanos.io/tip/thanos/getting-started.md/)
- [Helm Chart](https://github.com/stevehipwell/helm-charts/tree/main/charts/thanos)
- [GitHub Repository](https://github.com/thanos-io/thanos)
