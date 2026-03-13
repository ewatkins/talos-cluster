# [External Secrets Operator](https://external-secrets.io/)

Integrates external secret management systems with Kubernetes. Reads secrets from external APIs and automatically injects the values into Kubernetes `Secret` resources.

This cluster uses [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) as the secret store backend, accessed via the Bitwarden SDK server sidecar.

## Created Resources

| Kind | Name |
| --- | --- |
| [`Namespace`][ref-namespace] | `external-secrets` |
| [`HelmRelease`][ref-helm-release] | `external-secrets` |
| [`Certificate`][ref-certificate] | `bitwarden-tls-certs` |
| [`Certificate`][ref-certificate] | `bitwarden-css-certs` |

[ref-namespace]: https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/namespace-v1/
[ref-helm-release]: https://fluxcd.io/flux/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate

## Links

- [Documentation](https://external-secrets.io/latest/)
- [GitHub Repository](https://github.com/external-secrets/external-secrets)
- [Helm Chart](https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets)
