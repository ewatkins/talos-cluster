# flux-instance

The `FluxInstance` resource declares the desired Flux CD distribution and component configuration for this cluster. It is reconciled by the Flux Operator, which installs and upgrades Flux components accordingly.

## Flux Kustomization

| Setting | Value |
| --- | --- |
| Kustomization name | `flux-instance` |
| Namespace | `flux-system` |
| Path | `kubernetes/apps/flux-system/flux-instance/app` |
| Interval | 1h |
| Depends on | `flux-operator` |
| Wait | false |

## FluxInstance Configuration

| Setting | Value |
| --- | --- |
| Distribution version | `2.x` |
| Registry | `ghcr.io/fluxcd` |
| Reconcile interval | 1h (annotation `fluxcd.controlplane.io/reconcileEvery`) |
| Reconcile timeout | 5m |
| Cluster type | `kubernetes` |
| Multitenant | false |
| Network policy | false |
| Cluster domain | `cluster.local` |

### Components

| Component | Included |
| --- | --- |
| `source-controller` | yes |
| `kustomize-controller` | yes |
| `helm-controller` | yes |
| `notification-controller` | yes |
| `image-reflector-controller` | no |
| `image-automation-controller` | no |

### Performance Tuning (kustomize patches)

The following flags are added to `kustomize-controller`, `helm-controller`, and `source-controller`:

| Flag | Value |
| --- | --- |
| `--concurrent` | `8` |
| `--kube-api-qps` | `500` |
| `--kube-api-burst` | `1000` |
| `--requeue-dependency` | `5s` |

Resource limits for those three controllers:

| Resource | Limit |
| --- | --- |
| CPU | `2000m` |
| Memory | `2Gi` |

Helm controller OOM watch (applied to `helm-controller` only):

| Flag | Value |
| --- | --- |
| `--feature-gates` | `OOMWatch=true` |
| `--oom-watch-memory-threshold` | `95` |
| `--oom-watch-interval` | `500ms` |

## ExternalSecrets

Two `ExternalSecret` resources are defined in the `flux-system` namespace, both pulling from `ClusterSecretStore/bitwarden-secrets-manager` with a 15-minute refresh interval:

| ExternalSecret | Target Secret | Key Mapped |
| --- | --- | --- |
| `github-webhook-token-secret` | `github-webhook-token-secret` | `token` |
| `sops-age-secret` | `sops-age-secret` | `age.agekey` (from `SOPS_PRIVATE_KEY`) |

The `sops-age-secret` provides the Age private key that Flux uses to decrypt SOPS-encrypted secrets at reconcile time.

## Grafana Dashboards

Four `GrafanaDashboard` resources are deployed, all targeting the `grafana.internal/instance: grafana` Grafana instance with a Prometheus datasource:

| Dashboard | Source |
| --- | --- |
| `flux-k8s-api-performance` | `controlplaneio-fluxcd/flux-operator` repo |
| `flux-performance` | `controlplaneio-fluxcd/flux-operator` repo |
| `flux-cluster` | `fluxcd/flux2-monitoring-example` repo |
| `flux-control-plane` | `fluxcd/flux2-monitoring-example` repo |

## Links

- [FluxInstance API Reference](https://fluxcd.control-plane.io/operator/fluxinstance/)
- [Flux Documentation](https://fluxcd.io/flux/)
- [Flux Performance Tuning](https://fluxcd.io/flux/cheatsheets/bootstrap/#increase-the-number-of-workers)
- [Flux Helm OOM Watch](https://fluxcd.io/flux/cheatsheets/bootstrap/#enable-helm-near-oom-detection)
