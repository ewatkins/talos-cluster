# [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator)

The Flux Operator manages the Flux CD installation lifecycle. It reads a `FluxInstance` custom resource and installs, upgrades, and configures Flux components accordingly, replacing the need to manage Flux manifests directly.

## Flux Kustomization

| Setting | Value |
| --- | --- |
| Kustomization name | `flux-operator` |
| Namespace | `flux-system` |
| Path | `kubernetes/apps/flux-system/flux-operator/app` |
| Interval | 1h |
| Prune | true |

## Chart

The chart is pulled as an OCI artifact rather than from a Helm repository.

| Setting | Value |
| --- | --- |
| Source | `OCIRepository/flux-operator` |
| OCI URL | `oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator` |
| Tag | `0.44.0` |
| OCI poll interval | 15m |
| HelmRelease reconcile interval | 1h |

## Values

| Setting | Value |
| --- | --- |
| `serviceMonitor.create` | `true` |

A Prometheus `ServiceMonitor` is created to expose operator health and reconciliation metrics. All Flux component tuning (concurrency, resource limits, OOM watch) is configured in the [flux-instance](../flux-instance/README.md) `FluxInstance` resource.

## Links

- [Documentation](https://fluxcd.control-plane.io/operator/)
- [GitHub Repository](https://github.com/controlplaneio-fluxcd/flux-operator)
- [Helm Chart](https://github.com/controlplaneio-fluxcd/flux-operator/tree/main/charts/flux-operator)
