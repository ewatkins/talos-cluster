# [Minio](https://min.io/)

Minio is a high-performance, S3-compatible object storage server. It is used as the primary object store for Thanos long-term metric storage, Loki log storage, and Forgejo file attachments.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `minio` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `quay.io/minio/minio` RELEASE.2025-09-07T16-13-09Z
- Deployed via `bjw-s/app-template` chart v3.7.3
- S3 API accessible at `https://s3.ewatkins.dev` (port 9000)
- Web console accessible at `https://minio.ewatkins.dev` (port 9001)
- OpenID/OIDC integration disabled
- Data stored in `minio-data` PVC
- Prometheus ServiceMonitor scrapes cluster metrics at `/minio/v2/metrics/cluster`

## Links

- [Documentation](https://min.io/docs/minio/linux/index.html)
- [GitHub Repository](https://github.com/minio/minio)
