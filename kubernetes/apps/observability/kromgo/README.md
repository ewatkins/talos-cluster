# [Kromgo](https://github.com/kashalls/kromgo)

Exposes preconfigured Prometheus metrics as embeddable badges for use in READMEs and status pages.

## Adding Metrics

Metrics are configured in [app/resources/config.yaml](app/resources/config.yaml). Each metric specifies a PromQL query, optional suffix, and color thresholds.

```yaml
metrics:
  - name: cluster_cpu_usage
    query: round(avg(instance:node_cpu_utilisation:rate5m) * 100, 0.1)
    suffix: "%"
    colors:
      - { color: "green", min: 0, max: 35 }
      - { color: "orange", min: 36, max: 75 }
      - { color: "red", min: 76, max: 9999 }
    title: CPU
```

A `GET /cluster_cpu_usage` request returns:

```json
{
  "color": "brightgreen",
  "label": "cluster_cpu_usage",
  "message": "6.9%",
  "schemaVersion": 1
}
```

## Currently Exposed Metrics

| Metric | Description |
| --- | --- |
| `talos_version` | Talos OS version |
| `kubernetes_version` | Kubernetes version |
| `cluster_node_count` | Total number of nodes |
| `cluster_pod_count` | Total number of running pods |
| `cluster_cpu_usage` | Average CPU utilization |
| `cluster_memory_usage` | Average memory utilization |
| `cluster_power_usage` | Cluster power draw |
| `cluster_age_days` | Days since cluster creation |
| `cluster_uptime_days` | Days since last full restart |

## Links

- [GitHub Repository](https://github.com/kashalls/kromgo)
