# [Thanos](https://thanos.io/)

Thanos extends the kube-prometheus-stack Prometheus instance with long-term metric storage and a global query layer. Prometheus runs a Thanos sidecar that uploads compacted blocks to Minio. The Thanos query layer federates across the live sidecar and the store gateway to serve the full historical range.

## Components

| Component | Replicas | Purpose |
| --- | --- | --- |
| `query` | 2 | Federated query layer across the Prometheus sidecar and store gateway |
| `queryFrontend` | 2 | Query caching and sharding; this is what Grafana queries |
| `rule` | 2 | Prometheus-compatible recording and alerting rules |
| `storeGateway` | 1 | Serves historical blocks from object storage |
| `compact` | 1 | Downsamples and compacts stored metric blocks |

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Object store | Minio bucket `thanos` at `minio.storage.svc.cluster.local:9000` | Long-term metric storage |
| Retention raw | 14 days | Full-resolution data |
| Retention 5m | 30 days | 5-minute downsampled data |
| Retention 1h | 60 days | 1-hour downsampled data |
| Compact concurrency | 4 | Parallel compaction workers |
| Compact delete delay | 30 minutes | Grace period before deleting compacted source blocks |
| Persistence | `nfs-slow`, 10Gi | Shared by `compact`, `rule`, and `storeGateway` |

## Caching

Both `queryFrontend` and `storeGateway` load their cache configuration from the `thanos-cache-configmap` ConfigMap (in-memory cache). Reloader restarts affected pods automatically when the ConfigMap changes.

## Alerting

The `rule` component connects to Alertmanager via DNS SRV discovery (`alertmanager-operated.observability.svc.cluster.local`) and fires a `PrometheusDown` (critical) alert if the `kps-prometheus` scrape target disappears for more than 5 minutes.

## Links

- [Documentation](https://thanos.io/tip/thanos/getting-started.md/)
- [Helm Chart](https://github.com/stevehipwell/helm-charts/tree/main/charts/thanos)
- [GitHub Repository](https://github.com/thanos-io/thanos)
