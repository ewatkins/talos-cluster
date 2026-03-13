# [Loki](https://grafana.com/oss/loki/)

Loki is a horizontally scalable, highly available log aggregation system inspired by Prometheus. It indexes metadata (labels) rather than log content, making it cost-effective for large volumes of logs.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `loki` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `loki` v6.55.0 from the `grafana` Helm repository
- Deployment mode: `SingleBinary` (single replica)
- Storage backend: filesystem (NFS PVC `nfs-slow`, 20Gi)
- Log retention: 14 days
- Chunk encoding: snappy
- Schema: TSDB v13 (from 2024-04-01)
- Depends on `openebs` (storage namespace) for PVC provisioning

## Links

- [Documentation](https://grafana.com/docs/loki/latest/)
- [Helm Chart](https://github.com/grafana/loki/tree/main/production/helm/loki)
- [GitHub Repository](https://github.com/grafana/loki)
