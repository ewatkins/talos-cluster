# [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

A collection of Kubernetes manifests, Grafana dashboards, and Prometheus rules that provide end-to-end cluster monitoring via the Prometheus Operator.

## Components

| Component | Description |
| --- | --- |
| Prometheus | Time-series metrics collection and storage |
| Alertmanager | Alert deduplication, grouping, and routing |
| kube-state-metrics | Exposes Kubernetes object state as metrics |
| node-exporter | Exposes host-level hardware and OS metrics |

## Naming Convention

This cluster uses `fullNameOverride: kps` with `cleanPrometheusOperatorObjectNames: true`, which results in clean resource names:

| Resource | Name |
| --- | --- |
| Prometheus | `prometheus-kps-0` |
| Alertmanager | `alertmanager-kps-0` |
| Operator | `kps-operator-*` |
| kube-state-metrics | `kube-state-metrics-*` |

## Debugging

### High Memory / OOMKilled

- [Rancher monitoring docs](https://rancher.com/docs/rancher/v2.6/en/monitoring-alerting/)
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
