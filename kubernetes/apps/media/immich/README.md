# [Immich](https://immich.app/)

Immich is a high-performance, self-hosted photo and video backup solution with a mobile app, face recognition, and smart search powered by machine learning.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `immich` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/immich-app/immich-server` v2.5.6
- Machine learning image: `ghcr.io/immich-app/immich-machine-learning` v2.5.6
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://photos.ewatkins.dev` via Envoy Gateway HTTPRoute
- Backed by PostgreSQL (connection URL from `immich-db-secret`) and Dragonfly as Redis
- Photo library mounted via NFS from `caspian.local:/mnt/user/immich`
- Machine learning model cache stored in an OpenEBS hostpath PVC (10Gi)

## Links

- [Documentation](https://immich.app/docs/overview/introduction)
- [GitHub Repository](https://github.com/immich-app/immich)
