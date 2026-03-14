# [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

A collection of Kubernetes manifests, Grafana dashboards, and Prometheus rules that provide end-to-end cluster monitoring via the Prometheus Operator. Grafana is **disabled** in this chart — it is deployed as a separate app.

## Components

| Component | Replicas | Description |
| --- | --- | --- |
| Prometheus | 1 | Time-series metrics collection and storage |
| Alertmanager | 2 | Alert deduplication, grouping, and routing |
| kube-state-metrics | 1 | Exposes Kubernetes object state as metrics |
| node-exporter | 1 per node | Exposes host-level hardware and OS metrics |

## Naming Convention

This cluster uses `fullNameOverride: kps` with `cleanPrometheusOperatorObjectNames: true`, which results in clean resource names:

| Resource | Name |
| --- | --- |
| Prometheus | `prometheus-kps-0` |
| Alertmanager | `alertmanager-kps-0` |
| Operator | `kps-operator-*` |
| kube-state-metrics | `kube-state-metrics-*` |

## Prometheus Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Local retention | 2 days | Short-lived; long-term storage handled by Thanos |
| Local storage limit | 8 GiB | WAL compression enabled |
| Remote storage | Thanos sidecar | Uploads blocks to Minio via S3 |
| Replica label | `__replica__` | Used for Thanos deduplication |

Prometheus runs with a Thanos sidecar that exposes a gRPC store endpoint and uploads compacted blocks to the `thanos` Minio bucket. The Thanos query layer then federates across this sidecar and the store gateway to provide the full historical view.

## Alertmanager Configuration

| Setting | Value |
| --- | --- |
| Replicas | 2 |
| Retention | 72 hours |
| Storage | 1 GiB on `nfs-slow` |
| Config source | `alertmanager-secret` (ExternalSecret from Bitwarden) |

## Control Plane Scraping

`kubeControllerManager`, `kubeEtcd`, and `kubeScheduler` are scraped by targeting the three control plane node IPs directly (`10.40.1.1`, `10.40.1.2`, `10.40.1.3` — superior, huron, michigan). `kubeProxy` scraping is disabled (Cilium replaces kube-proxy).

Etcd metrics are served on port `2381` (non-TLS).

## Cardinality Management

Several high-cardinality label sets are dropped at scrape time to keep storage manageable:

- **kubelet**: drops `uid`, `id`, `name` labels and several high-bucket `rest_client` duration metrics
- **kubeApiServer**: drops high-bucket `apiserver`/`etcd`/`rest_client` duration and size metrics

## Debugging

### High Memory / OOMKilled

- [Identifying metrics driving high cardinality](https://www.robustperception.io/which-are-my-biggest-metrics)

### Deleting a Stuck Metric Series

```sh
# Delete all series for a metric
curl -X POST -g "https://prometheus.ewatkins.dev/api/v1/admin/tsdb/delete_series?match[]=<METRIC_NAME>"

# Delete series for a specific scrape job
curl -X POST -g "https://prometheus.ewatkins.dev/api/v1/admin/tsdb/delete_series?match[]=<METRIC_NAME>{job='<SCRAPE_JOB>'}"
```

## Links

- [Documentation](https://prometheus.io/docs/)
- [GitHub Repository](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator Docs](https://prometheus-operator.dev/)
