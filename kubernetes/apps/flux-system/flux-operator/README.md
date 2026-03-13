# [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator)

The Flux Operator is a Kubernetes operator that manages the lifecycle of the Flux CD distribution. It installs, upgrades, and configures Flux components declared in a `FluxInstance` custom resource.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `flux-operator` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `flux-operator` v0.43.0 from `oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator`
- Prometheus ServiceMonitor is enabled

## Links

- [Documentation](https://fluxcd.control-plane.io/operator/)
- [GitHub Repository](https://github.com/controlplaneio-fluxcd/flux-operator)
- [Helm Chart](https://github.com/controlplaneio-fluxcd/flux-operator/tree/main/charts/flux-operator)
