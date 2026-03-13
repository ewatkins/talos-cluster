# [Recommendarr](https://github.com/tannermiddleton/recommendarr)

Recommendarr is an AI-powered media recommendation engine that integrates with Sonarr and Radarr to suggest new TV shows and movies based on your existing library using large language models.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `recommendarr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `docker.io/tannermiddleton/recommendarr` v1.4.4
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://recommend.ewatkins.dev`
- Data stored in `recommendarr-data` PVC

## Links

- [GitHub Repository](https://github.com/tannermiddleton/recommendarr)
