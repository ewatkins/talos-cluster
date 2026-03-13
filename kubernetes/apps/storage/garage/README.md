# [Garage](https://garagehq.deuxfleurs.fr/)

Garage is a lightweight, distributed S3-compatible object store designed for self-hosted deployments. It is used as an alternative to Minio for certain workloads and exposes an S3 endpoint at `s3-garage.ewatkins.dev`.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `garage` |
| [`HelmRelease`][ref-helm-release] | `garage-webui` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `dxflrs/garage` v2.2.0
- WebUI image: `khairul169/garage-webui` v1.1.0
- Both deployed via `bjw-s/app-template` (OCI)
- S3 API on port 3900, admin API on port 3903
- WebUI accessible at `https://garage.ewatkins.dev` via Envoy Gateway HTTPRoute
- Config via `garage-configmap`, credentials from `garage-secret`
- Data and metadata stored in dedicated PVCs (`garage-data`, `garage-meta`)

## Links

- [Documentation](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
- [GitHub Repository](https://git.deuxfleurs.fr/Deuxfleurs/garage)
