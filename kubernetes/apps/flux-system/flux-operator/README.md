# [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator)

The Flux Operator manages the Flux CD installation lifecycle. It reads a `FluxInstance` custom resource and installs, upgrades, and configures Flux components accordingly, replacing the need to manage Flux manifests directly.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Metrics | Prometheus ServiceMonitor | Exposes operator health and reconciliation metrics |

The operator's configuration is minimal — most Flux tuning lives in the [flux-instance](../flux-instance/README.md) `FluxInstance` resource.

## Links

- [Documentation](https://fluxcd.control-plane.io/operator/)
- [GitHub Repository](https://github.com/controlplaneio-fluxcd/flux-operator)
- [Helm Chart](https://github.com/controlplaneio-fluxcd/flux-operator/tree/main/charts/flux-operator)
