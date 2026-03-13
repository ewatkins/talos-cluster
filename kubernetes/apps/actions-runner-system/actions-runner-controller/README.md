# [Actions Runner Controller](https://github.com/actions/actions-runner-controller)

GitHub Actions Runner Controller (ARC) manages self-hosted GitHub Actions runner scale sets on Kubernetes, automatically scaling runners up and down based on workflow demand.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `actions-runner-controller` |
| [`HelmRelease`][ref-helm-release] | `talos-runner` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- The controller uses chart `gha-runner-scale-set-controller` v0.13.1 from `oci://ghcr.io/actions/actions-runner-controller-charts`
- The runner scale set (`talos-runner`) targets `https://github.com/ewatkins/talos-cluster` with 1–3 runners
- Runners run in `kubernetes` container mode using NFS-backed work volumes (`nfs-fast`, 10Gi)
- Runner image: `ghcr.io/home-operations/actions-runner`
- Runners have access to Talos client credentials via a mounted secret

## Links

- [Documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller)
- [GitHub Repository](https://github.com/actions/actions-runner-controller)
- [Helm Chart (controller)](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set-controller)
- [Helm Chart (scale set)](https://github.com/actions/actions-runner-controller/tree/master/charts/gha-runner-scale-set)
