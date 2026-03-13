# [Actions Runner Controller](https://github.com/actions/actions-runner-controller)

GitHub Actions Runner Controller (ARC) manages self-hosted GitHub Actions runner scale sets on Kubernetes, automatically scaling runners up and down based on workflow demand. This cluster runs a dedicated scale set targeting the `talos-cluster` repository.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Target repository | `https://github.com/ewatkins/talos-cluster` | Runners only accept jobs from this repo |
| Runner scale | 1–3 replicas | Scales up on queued jobs, down when idle |
| Container mode | `kubernetes` | Each job step runs in its own Kubernetes pod |
| Work volume | `nfs-fast`, 10Gi | NFS-backed storage for job workspace data |
| Runner image | `ghcr.io/home-operations/actions-runner` | Custom image with Talos and cluster tooling pre-installed |
| Talos credentials | Mounted secret | Gives runners access to `talosctl` for upgrade tasks |

## Links

- [Documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller)
- [GitHub Repository](https://github.com/actions/actions-runner-controller)
- [Helm Chart (controller)](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set-controller)
- [Helm Chart (scale set)](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set)
