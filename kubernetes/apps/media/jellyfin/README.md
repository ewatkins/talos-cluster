# [Jellyfin](https://jellyfin.org/)

Jellyfin is a free and open-source media server that puts you in control of managing and streaming your media collection.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `jellyfin` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/jellyfin/jellyfin` v10.11.6
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://jellyfin.ewatkins.dev` with a dedicated LoadBalancer IP (`${JELLYFIN}`)
- Hardware transcoding via Intel GPU using Dynamic Resource Allocation (DRA)
- Media library mounted via NFS from `caspian.local:/mnt/user/arrdata`
- Config, data, and cache stored in dedicated PVCs

## Links

- [Documentation](https://jellyfin.org/docs/)
- [GitHub Repository](https://github.com/jellyfin/jellyfin)
