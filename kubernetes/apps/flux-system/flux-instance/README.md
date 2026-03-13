# flux-instance

The `FluxInstance` resource declares the desired Flux CD distribution and component configuration for this cluster. It is reconciled by the Flux Operator, which installs and upgrades Flux components accordingly.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Distribution | Flux `2.x` from `ghcr.io/fluxcd` | Operator pins and upgrades the version automatically |
| Components | `source-controller`, `kustomize-controller`, `helm-controller`, `notification-controller` | Standard set; image-reflector and image-automation are not used |
| Concurrency | `--concurrent=8` | Number of parallel reconciliations per controller |
| API throughput | `--kube-api-qps=500`, `--kube-api-burst=1000` | Tuned for a large number of HelmReleases and Kustomizations |
| Helm OOM watch | `OOMWatch=true` | Helm controller restarts automatically if it runs out of memory |

## Links

- [FluxInstance API Reference](https://fluxcd.control-plane.io/operator/fluxinstance/)
- [Flux Documentation](https://fluxcd.io/flux/)
