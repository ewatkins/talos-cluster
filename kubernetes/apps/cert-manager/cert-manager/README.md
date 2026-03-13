# [cert-manager](https://cert-manager.io/)

cert-manager is a Kubernetes operator that automates the management and issuance of TLS certificates from a variety of sources, including ACME (Let's Encrypt), self-signed, and CA issuers.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `cert-manager` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Helm chart: `cert-manager` v1.20.0 from the `jetstack` repository
- CRDs are installed and updated automatically (`installCRDs: true`)
- DNS-01 challenge uses recursive nameservers `1.1.1.1` and `9.9.9.9`
- Prometheus ServiceMonitor is enabled for metrics scraping
- A self-signed `ClusterIssuer` is deployed alongside the operator

## Links

- [Documentation](https://cert-manager.io/docs/)
- [Helm Chart](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager)
- [GitHub Repository](https://github.com/cert-manager/cert-manager)
