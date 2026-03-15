# [External Secrets Operator](https://external-secrets.io/)

Syncs secrets from external secret management systems into Kubernetes `Secret` resources. This cluster uses [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) as the backend, accessed via the bundled `bitwarden-sdk-server` sidecar.

## Flux Kustomizations

Three Flux `Kustomization` resources are defined in `ks.yaml`, applied in dependency order:

| Kustomization | Path | Depends On | Interval |
| --- | --- | --- | --- |
| `external-secrets-certificates` | `certificates/` | — | 120m |
| `external-secrets` | `app/` | `external-secrets-certificates` | 120m |
| `external-secrets-stores` | `stores/bitwarden-secrets/` | `external-secrets` | 120m |

## HelmRelease

| Setting | Value |
| --- | --- |
| Chart | `external-secrets` |
| Version | `2.1.0` |
| Source | `HelmRepository/external-secrets` in `flux-system` |
| Reconcile interval | 30m |
| Install retries | 3 |
| Upgrade strategy | rollback (3 retries, cleanupOnFail) |
| CRDs | installed by chart (`installCRDs: true`) |
| Bitwarden SDK server | enabled |
| ServiceMonitor (operator) | enabled, interval 1m |
| ServiceMonitor (cert-controller) | enabled, interval 1m |
| ServiceMonitor (reports-controller) | enabled, interval 1m |

The `bitwarden-sdk-server` pod is annotated to reload when any of the following secrets change: `bitwarden-css-certs`, `bitwarden-secrets-manager`, `bitwarden-secrets-manager-secrets`, `bitwarden-tls-certs`, `bitwarden-access-token`.

## Certificates

Two `Certificate` resources are created in the `external-secrets` namespace by cert-manager, both issued by `ClusterIssuer/home-ca-issuer` using RSA 2048-bit PKCS8 keys with `rotationPolicy: Always`.

| Certificate | Secret | Purpose | Duration | Renew Before |
| --- | --- | --- | --- | --- |
| `bitwarden-tls-certs` | `bitwarden-tls-certs` | TLS for the SDK server (server cert) | 168h (7d) | 24h |
| `bitwarden-css-certs` | `bitwarden-css-certs` | mTLS client auth for the CSS | — | — |

`bitwarden-tls-certs` covers the following SANs:
- `external-secrets-bitwarden-sdk-server.external-secrets.svc.cluster.local`
- `bitwarden-sdk-server.external-secrets.svc.cluster.local`
- `bitwarden-sdk-server.external-secrets`
- `bitwarden-sdk-server`
- `localhost`
- `127.0.0.1`, `::1`

## ClusterSecretStore

A `ClusterSecretStore` named `bitwarden-secrets-manager` connects to Bitwarden using the SDK server sidecar.

| Setting | Value |
| --- | --- |
| API URL | `https://api.bitwarden.com` |
| Identity URL | `https://identity.bitwarden.com` |
| SDK server URL | `https://bitwarden-sdk-server.external-secrets.svc.cluster.local:9998` |
| Credentials secret | `bws-secrets` (key: `bws_token`) in `flux-system` |
| CA cert | `bitwarden-css-certs` Secret, key `ca.crt` in `external-secrets` |
| Organization ID | `${bws_organizationID}` (Flux variable substitution) |
| Project ID | `${bws_projectID_talos}` (Flux variable substitution) |

## Links

- [Documentation](https://external-secrets.io/latest/)
- [GitHub Repository](https://github.com/external-secrets/external-secrets)
- [Helm Chart](https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets)
- [Bitwarden Secrets Manager Provider](https://external-secrets.io/latest/provider/bitwarden-secrets-manager/)
- [Bitwarden SDK Server](https://github.com/external-secrets/bitwarden-sdk-server)
