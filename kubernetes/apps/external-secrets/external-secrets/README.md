# `external-secrets`

## Introduction

**External Secrets Operator** is a Kubernetes operator that integrates external
secret management systems like [AWS Secrets
Manager](https://aws.amazon.com/secrets-manager/), [HashiCorp
Vault](https://www.vaultproject.io/), [Google Secrets
Manager](https://cloud.google.com/secret-manager), [Azure Key
Vault](https://azure.microsoft.com/en-us/services/key-vault/), [IBM Cloud Secrets Manager](https://www.ibm.com/cloud/secrets-manager), [Akeyless](https://akeyless.io), [CyberArk Conjur](https://www.conjur.org), [Pulumi ESC](https://www.pulumi.com/product/esc/) and many more. The
operator reads information from external APIs and automatically injects the
values into a [Kubernetes
Secret](https://kubernetes.io/docs/concepts/configuration/secret/).

![External-Secrets components](/docs/assets/diagrams-component-overview.png){ loading=lazy }

## Created Resources

| Kind                                | Name               |
| ----------------------------------- | ------------------ |
| [`Namespace`][ref-namespace]        | `external-secrets` |
| [`HelmRelease`][ref-helm-release]   | `external-secrets` |
| [`Certificate`][ref-certificate]    | `vault.${DOMAIN_INTERNAL}`  |
| [`IngressRoute`][ref-ingress-route] | `dashboard`        |

[ref-namespace]: https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/namespace-v1/
[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://external-secrets.io/latest/)
- [Helm Chart](https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets)
- [GitHub Repository](https://github.com/external-secrets/external-secrets/)
