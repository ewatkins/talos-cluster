# [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/)

Promtail is an agent that ships the contents of local container logs to a Loki instance. It runs as a DaemonSet on every node and automatically discovers and tails pod log files.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `promtail` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `promtail` v6.17.1 from the `grafana` Helm repository
- Pushes logs to `http://loki-headless.observability.svc.cluster.local:3100/loki/api/v1/push`
- Prometheus ServiceMonitor enabled

## Links

- [Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/promtail)
- [GitHub Repository](https://github.com/grafana/loki/tree/main/clients/pkg/promtail)
