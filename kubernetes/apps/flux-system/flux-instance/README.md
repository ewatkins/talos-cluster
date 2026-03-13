# flux-instance

The `FluxInstance` resource declares the desired Flux CD distribution and component configuration for this cluster. It is reconciled by the Flux Operator.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`FluxInstance`][ref-fluxinstance] | `flux` |

[ref-fluxinstance]: https://fluxcd.control-plane.io/operator/fluxinstance/

## Notes

- Deploys Flux `2.x` from `ghcr.io/fluxcd`
- Components: `source-controller`, `kustomize-controller`, `helm-controller`, `notification-controller`
- Workers tuned for high throughput: `--concurrent=8`, `--kube-api-qps=500`, `--kube-api-burst=1000`
- Helm controller has OOM watch enabled (`OOMWatch=true`)

## Links

- [FluxInstance API Reference](https://fluxcd.control-plane.io/operator/fluxinstance/)
- [Flux Documentation](https://fluxcd.io/flux/)
