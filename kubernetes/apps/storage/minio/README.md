# [Minio](https://min.io/)

Minio is the primary S3-compatible object store for this cluster. It backs Thanos long-term metric storage, Loki log storage, and Forgejo file attachments, providing a single internal S3 endpoint consumed by observability and application workloads.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| S3 API | `https://s3.ewatkins.dev` (port 9000) | S3 endpoint used by Thanos, Loki, and Forgejo |
| Web console | `https://minio.ewatkins.dev` (port 9001) | Browser-based management interface |
| OpenID/OIDC | Disabled | OIDC integration was removed after Authentik was decommissioned |
| Data storage | `minio-data` PVC | Single PVC backing all buckets |
| Metrics | Prometheus ServiceMonitor at `/minio/v2/metrics/cluster` | Cluster-level storage and throughput metrics |

## Consumers

| App | Bucket | Purpose |
| --- | --- | --- |
| [Thanos](../../observability/thanos/README.md) | `thanos` | Long-term Prometheus metric storage |
| [Loki](../../observability/loki/README.md) | `loki` | Log chunk storage (when configured for object store) |
| [Forgejo](../../development/forgejo/README.md) | `forgejo` | LFS objects, release attachments, avatars |

## Links

- [Documentation](https://min.io/docs/minio/linux/index.html)
- [GitHub Repository](https://github.com/minio/minio)
