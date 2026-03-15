# Bitwarden Secrets Manager — ClusterSecretStore

A cluster-wide `ClusterSecretStore` that enables any namespace to pull secrets from Bitwarden Secrets Manager via the `bitwarden-sdk-server` sidecar running in the `external-secrets` namespace.

## Configuration

| Setting | Value |
| --- | --- |
| Name | `bitwarden-secrets-manager` |
| API URL | `https://api.bitwarden.com` |
| Identity URL | `https://identity.bitwarden.com` |
| SDK server URL | `https://bitwarden-sdk-server.external-secrets.svc.cluster.local:9998` |
| Credentials secret | `bws-secrets` (key: `bws_token`) in `flux-system` |
| CA cert | `bitwarden-css-certs` Secret, key `ca.crt` in `external-secrets` |
| Organization ID | `${bws_organizationID}` |
| Project ID | `${bws_projectID_talos}` |

The `organizationID` and `projectID` values are injected at reconcile time via Flux post-build variable substitution from `cluster-secrets`.

## Links

- [External Secrets — Bitwarden Provider Docs](https://external-secrets.io/latest/provider/bitwarden-secrets-manager/)
- [Bitwarden SDK Server](https://github.com/external-secrets/bitwarden-sdk-server)
- [cert-manager CA Injector](https://cert-manager.io/docs/concepts/ca-injector/)
- [Bootstrapping CA Issuers](https://cert-manager.io/docs/configuration/selfsigned/#bootstrapping-ca-issuers)
