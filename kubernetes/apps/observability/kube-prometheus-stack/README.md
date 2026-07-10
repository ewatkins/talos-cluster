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
| Local block size limit | 15 GiB | `retentionSize`; bounds persisted blocks only, **not** the WAL |
| PVC size | 25 GiB | Headroom so WAL spikes don't drive the node into `DiskPressure` |
| Memory | 1 Gi request / 2 Gi limit | Reserved to avoid OOM/evict crash-loops during WAL replay |
| Remote storage | Thanos sidecar | Uploads blocks to Minio via S3 |
| Replica label | `__replica__` | Used for Thanos deduplication |

> **Note:** `openebs-hostpath` PVs share the node's `/var` filesystem and are not
> quota-enforced, so the PVC size is nominal. The real guard against a runaway WAL
> filling the node is keeping Prometheus from crash-looping (adequate memory) plus
> the retention settings above. See [Runaway WAL](#runaway-wal--diskpressure-evictions).

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

### Runaway WAL / DiskPressure evictions

If a node hosting `prometheus-kps-0` starts evicting pods with
`The node had condition: [DiskPressure]`, the TSDB write-ahead log has likely
ballooned and filled the node's `/var` filesystem. This happens when Prometheus
crash-loops (OOM/evicted) and never survives long enough to compact the head into
a block and truncate the WAL — a self-sustaining loop, since the pod is pinned to
the node by its local PV.

Diagnose (michigan = `10.40.1.3`):

```sh
talosctl -n <node-ip> usage -H -d 2 /var/openebs/local/<pvc-id>/prometheus-db   # is `wal` huge?
kubectl get node <node> -o jsonpath='{.spec.taints}'                            # disk-pressure taint?
```

Recover (resets local TSDB only; long-term data is safe in Thanos):

```sh
kubectl -n observability patch prometheus kps --type merge -p '{"spec":{"replicas":0}}'
kubectl -n observability delete pvc prometheus-kps-db-prometheus-kps-0   # reclaim=Delete frees the dir
kubectl -n observability patch prometheus kps --type merge -p '{"spec":{"replicas":1}}'
```

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
