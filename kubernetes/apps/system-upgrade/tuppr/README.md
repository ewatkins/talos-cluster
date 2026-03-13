# [tuppr](https://github.com/home-operations/charts/tree/main/charts/tuppr)

tuppr manages automated, sequential upgrades of Talos Linux OS and Kubernetes versions across cluster nodes. It replaced the system-upgrade-controller and operates by reading upgrade specs from the `upgrades/` directory.

## Upgrade Specs

| File | Purpose |
| --- | --- |
| `upgrades/talosupgrade.yaml` | Specifies the target Talos OS version and installer image |
| `upgrades/kubernetesupgrade.yaml` | Specifies the target Kubernetes version |

To trigger an upgrade, update the version field in the appropriate spec file and commit to Git. Flux reconciles the change, and tuppr performs a rolling upgrade — one node at a time — ensuring cluster availability throughout.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Replicas | 2 | Leader election ensures only one instance drives upgrades at a time |
| Metrics | Prometheus ServiceMonitor | Exposes upgrade progress and status metrics |

## Links

- [GitHub Repository](https://github.com/home-operations/charts)
