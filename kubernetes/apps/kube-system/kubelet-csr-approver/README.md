# [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver)

kubelet-csr-approver automatically approves Kubernetes `CertificateSigningRequest` resources submitted by kubelets, removing the need for manual approval of node certificates.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `kubelet-csr-approver` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `kubelet-csr-approver` v1.2.13 from the `postfinance` Helm repository
- Configured to approve CSRs from nodes: `superior`, `huron`, `michigan`, `erie`, `ontario`, `tahoe`
- DNS resolution is bypassed (`bypassDnsResolution: true`) to handle Talos node name resolution
- Prometheus ServiceMonitor enabled

## Links

- [GitHub Repository](https://github.com/postfinance/kubelet-csr-approver)
- [Helm Chart](https://github.com/postfinance/kubelet-csr-approver/tree/main/deploy/charts/kubelet-csr-approver)
