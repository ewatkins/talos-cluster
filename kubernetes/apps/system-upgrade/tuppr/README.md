# [tuppr](https://github.com/home-operations/charts/tree/main/charts/tuppr)

tuppr is a Talos Linux upgrade controller that manages automated, sequential upgrades of Talos OS and Kubernetes versions across cluster nodes. It replaced the system-upgrade-controller in this cluster.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `tuppr` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `tuppr` v0.1.1 from `oci://ghcr.io/home-operations/charts/tuppr`
- Runs 2 replicas for availability
- Upgrade specs are defined in `upgrades/` directory:
  - `talosupgrade.yaml` — specifies the target Talos version
  - `kubernetesupgrade.yaml` — specifies the target Kubernetes version
- Prometheus ServiceMonitor enabled

## Links

- [GitHub Repository](https://github.com/home-operations/charts)
