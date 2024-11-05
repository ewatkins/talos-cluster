# [Kromgo](https://github.com/kashalls/kromgo)

Easily expose preconfigured prometheus metrics to the outside using badges.

## Metrics

Metrics that should be exposed for badges can be added to the [config](app/resources/config.yaml) file.

### _Example_

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

The above metric can be accessed with a GET request to `/cluster_cpu_usage` and returns:

```json
{
  "color":"brightgreen",
  "label":"cluster_cpu_usage",
  "message":"6.9%",
  "schemaVersion":1
}
```

## Currently Exposed Metrics

- talos_version
- kubernetes_version
- cluster_node_count
- cluster_pod_count
- cluster_cpu_usage
- cluster_memory_usage
- cluster_power_usage
- cluster_age_days
- cluster_uptime_days
