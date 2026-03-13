# [Spegel](https://github.com/spegel-org/spegel)

Spegel is a stateless cluster-local OCI registry mirror that allows cluster nodes to share container image layers with each other via peer-to-peer distribution, reducing external registry traffic and improving pull performance.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `spegel` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `spegel` v0.6.0 from the `spegel` Helm repository
- Uses containerd socket at `/run/containerd/containerd.sock`
- Registry config path: `/etc/cri/conf.d/hosts`
- Registry host port: `29999`
- Prometheus ServiceMonitor enabled

## Links

- [Documentation](https://spegel.dev/)
- [Helm Chart](https://github.com/spegel-org/spegel/tree/main/charts/spegel)
- [GitHub Repository](https://github.com/spegel-org/spegel)
