# [MinIO](https://min.io/)

MinIO is the primary S3-compatible object store for this cluster. It backs Thanos long-term metric storage, Loki log storage, and Forgejo file attachments.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z` | |
| Chart | `app-template 3.7.3` from HelmRepository `bjw-s` | |
| S3 API URL | `https://s3.ewatkins.dev` (port 9000) | Internal gateway (`internal`); DNS via `internal.ewatkins.dev` |
| Web console URL | `https://minio.ewatkins.dev` (port 9001) | Internal gateway; DNS via `internal.ewatkins.dev` |
| Data PVC | `minio-data`, 20Gi, `ReadWriteMany` | StorageClass `nfs-fast` on `storage.ewatkins.dev:/mnt/user/kubernetes-fast` |
| Credentials | `minio-secret` | `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` from Bitwarden Secrets Manager |
| OIDC | Disabled | `MINIO_IDENTITY_OPENID_ENABLE: "off"` |
| Auto-update | Disabled | `MINIO_UPDATE: "off"` |
| Prometheus metrics | `/minio/v2/metrics/cluster` (port 9000) | Auth type `public`; Prometheus URL `https://prometheus.ewatkins.dev`; job ID `minio` |
| Metrics scrape interval | 1m | ServiceMonitor scrape timeout 10s |
| Resources | requests: 100m CPU; limits: 2Gi memory | |
| CORS origins | `https://minio.ewatkins.dev`, `https://s3.ewatkins.dev` | |

## Secrets

| Secret | Source | Contents |
| --- | --- | --- |
| `minio-secret` | Bitwarden Secrets Manager | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` |

## Consumers

| App | Bucket | Purpose |
| --- | --- | --- |
| [Thanos](../../observability/thanos/README.md) | `thanos` | Long-term Prometheus metric storage |
| [Loki](../../observability/loki/README.md) | `loki` | Log chunk and index storage |
| [Forgejo](../../development/forgejo/README.md) | `forgejo` | LFS objects, release attachments, avatars |

## Links

- [Documentation](https://min.io/docs/minio/linux/index.html)
- [GitHub Repository](https://github.com/minio/minio)
