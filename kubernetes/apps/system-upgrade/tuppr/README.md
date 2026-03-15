# [tuppr](https://github.com/home-operations/charts/tree/main/charts/tuppr)

tuppr manages automated, sequential upgrades of Talos Linux OS and Kubernetes versions across cluster nodes. It replaced the system-upgrade-controller. tuppr reads `TalosUpgrade` and `KubernetesUpgrade` custom resources from the `upgrades/` directory and upgrades nodes one at a time, ensuring cluster availability throughout.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `tuppr 0.1.2` via `oci://ghcr.io/home-operations/charts/tuppr` | Chart polled every 15m |
| Helm release interval | 1h | |
| Replicas | 2 | Leader election ensures only one instance drives upgrades at a time |
| Metrics | Prometheus ServiceMonitor enabled | |
| Flux interval | 1h | Both `tuppr` and `tuppr-upgrades` Kustomizations reconcile every hour |

## Upgrade Specs

| File | Kind | Current Target |
| --- | --- | --- |
| `upgrades/talosupgrade.yaml` | `TalosUpgrade` | Talos `v1.12.5`; reboot mode `powercycle` |
| `upgrades/kubernetesupgrade.yaml` | `KubernetesUpgrade` | Kubernetes `v1.35.2` |

Both version fields are annotated with Renovate datasource comments so Renovate Bot automatically creates PRs when new versions are available.

## Triggering an Upgrade

Update the `spec.talos.version` or `spec.kubernetes.version` field in the appropriate spec file and commit to Git. Flux reconciles the change on the next interval (up to 1 hour) and tuppr performs a rolling upgrade node by node.

## Flux Dependencies

The `tuppr-upgrades` Kustomization `dependsOn` the `tuppr` Kustomization, ensuring the controller and its CRDs are installed before upgrade specs are applied.

## Links

- [GitHub Repository](https://github.com/home-operations/charts/tree/main/charts/tuppr)
- [Talos Linux Upgrade Documentation](https://www.talos.dev/latest/talos-guides/upgrading-talos/)
- [Kubernetes Upgrade Documentation](https://www.talos.dev/latest/kubernetes-guides/upgrading-kubernetes/)
