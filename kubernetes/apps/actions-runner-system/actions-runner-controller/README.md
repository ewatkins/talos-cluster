# [Actions Runner Controller](https://github.com/actions/actions-runner-controller)

Actions Runner Controller (ARC) manages self-hosted GitHub Actions runners on Kubernetes as autoscaling runner scale sets. This cluster deploys one scale set — `talos-runner` — scoped to the `talos-cluster` repository.

## Components

There are two separate Helm releases:

| Release | Chart | Purpose |
| --- | --- | --- |
| `actions-runner-controller` | `gha-runner-scale-set-controller` | The ARC controller itself; watches for queued jobs and manages runner pod lifecycle |
| `talos-runner` | `gha-runner-scale-set` | The runner scale set registered to the `talos-cluster` repo |

Both charts are pulled from the OCI registry at `ghcr.io/actions/actions-runner-controller-charts`.

## Runner Scale Set Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Target repository | `https://github.com/ewatkins/talos-cluster` | Only accepts jobs queued against this repo |
| Min / max runners | 1 – 3 | ARC scales up when jobs are queued, back to 1 when idle |
| Container mode | `kubernetes` | Each workflow job gets its own pod; job steps run as containers within it |
| Work volume | `nfs-fast`, 10Gi | Per-job PVC provisioned for the workspace; shared across all steps in a job |
| Runner image | `ghcr.io/home-operations/actions-runner` | Custom image with Talos and cluster tooling pre-installed |
| Job container required | `false` | `ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER=false` allows steps to run directly on the runner pod rather than requiring a container image |
| Node IP | Exposed as `$NODE` | The runner's host IP is injected so workflows can target specific nodes if needed |

## Authentication

Runners authenticate to GitHub using a **GitHub App** (not a personal access token). The `talos-runner-secret` is populated by an ExternalSecret from Bitwarden and contains:

| Field | Description |
| --- | --- |
| `github_app_id` | GitHub App ID |
| `github_app_installation_id` | Installation ID for the `talos-cluster` repo |
| `github_app_private_key` | App private key (base64-decoded from Bitwarden) |

## Permissions

The `talos-runner` ServiceAccount is granted two sets of privileges:

**Kubernetes (`ClusterRoleBinding` → `cluster-admin`)**
Runners have full cluster-admin access. This is required for tasks like applying manifests, running `kubectl`, and interacting with Flux during CI.

**Talos (`talos.dev/v1alpha1 ServiceAccount` → `os:admin`)**
A Talos-native ServiceAccount is created alongside the Kubernetes one. This provisions a `talosctl` credential at `/var/run/secrets/talos.dev` inside the runner pod, giving workflows OS-level admin access to all cluster nodes — used for node upgrades and Talos configuration tasks.

## How It Works

1. A workflow in the `talos-cluster` repo targets `runs-on: talos-runner`
2. GitHub notifies ARC via the GitHub App webhook
3. The controller scales up a runner pod (up to `maxRunners: 3`) to handle the job
4. ARC provisions a fresh 10Gi `nfs-fast` PVC as the job workspace
5. Each job step runs in a container spun up inside that pod
6. When the job finishes, the pod and PVC are torn down; the runner count scales back toward `minRunners: 1`

## Links

- [Documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller)
- [GitHub Repository](https://github.com/actions/actions-runner-controller)
- [Controller Helm Chart](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set-controller)
- [Scale Set Helm Chart](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set)
