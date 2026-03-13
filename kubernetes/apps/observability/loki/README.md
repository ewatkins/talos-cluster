# [Loki](https://grafana.com/oss/loki/)

Loki is the log aggregation backend for this cluster. It receives logs from Promtail running on every node and stores them for querying via Grafana. It indexes log metadata (labels) rather than full log content, keeping storage requirements low.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Deployment mode | `SingleBinary` | Single-replica deployment suitable for a home lab workload |
| Storage backend | Filesystem on `nfs-slow` PVC (20Gi) | Logs are written to NFS-backed storage |
| Retention | 14 days | Logs older than 14 days are automatically deleted |
| Chunk encoding | snappy | Compression format for stored log chunks |
| Schema | TSDB v13 (from 2024-04-01) | Index format; changing this requires a schema migration |

## Links

- [Documentation](https://grafana.com/docs/loki/latest/)
- [Helm Chart](https://github.com/grafana/loki/tree/main/production/helm/loki)
- [GitHub Repository](https://github.com/grafana/loki)
