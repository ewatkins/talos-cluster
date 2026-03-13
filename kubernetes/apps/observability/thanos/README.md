# [Thanos](https://thanos.io/)

Thanos extends Prometheus with global query view, long-term storage, and high availability. It stores metrics in Minio (S3-compatible object storage) and provides a unified query interface across multiple Prometheus instances.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `thanos` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `thanos` v1.23.0 from the `stevehipwell` Helm repository
- Object store: Minio bucket `thanos` via `minio.storage.svc.cluster.local:9000`
- Retention: raw 14d, 5m resolution 30d, 1h resolution 60d
- Components enabled: `compact`, `query` (2 replicas), `queryFrontend` (2 replicas), `rule` (2 replicas), `storeGateway` (1 replica)
- Alertmanager integration configured for PrometheusDown alerting
- Prometheus ServiceMonitor enabled
- Depends on `openebs` and `minio`

## Links

- [Documentation](https://thanos.io/tip/thanos/getting-started.md/)
- [Helm Chart](https://github.com/stevehipwell/helm-charts/tree/main/charts/thanos)
- [GitHub Repository](https://github.com/thanos-io/thanos)
