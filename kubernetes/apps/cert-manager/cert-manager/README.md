# [cert-manager](https://cert-manager.io/)

cert-manager automates the management and issuance of TLS certificates for the cluster. It handles ACME DNS-01 challenges against Cloudflare for the `ewatkins.dev` zone and provides self-signed CA issuers for internal services.

## Configuration

### Helm Chart

| Setting | Value |
| --- | --- |
| Chart | `jetstack/cert-manager` v1.20.0 |
| CRDs | Installed and managed by the Helm chart (`installCRDs: true`) |
| DNS-01 recursive nameservers | `1.1.1.1:53`, `9.9.9.9:53` |
| DNS-01 nameservers only | `true` (disables DNS-01 via authoritative servers) |
| Pod DNS policy | `None` (uses explicit pod DNS config) |
| Pod DNS nameservers | `1.1.1.1`, `9.9.9.9` |
| Metrics | Prometheus `ServiceMonitor` enabled |

### Resource Limits

| Component | CPU Request | Memory Request | Memory Limit |
| --- | --- | --- | --- |
| Controller | `15m` | `110M` | `110M` |
| Webhook | `15m` | `105M` | `105M` |
| CAInjector | `15m` | `110M` | `110M` |

## Issuers

### ACME (Let's Encrypt)

Both issuers use Cloudflare DNS-01 challenges scoped to the `ewatkins.dev` DNS zone. The Cloudflare API token is stored in the `cert-manager-secret` Secret, sourced from a SOPS-encrypted secret committed to Git (`cert-manager-secret.secret.sops.yaml`).

| ClusterIssuer | ACME Server |
| --- | --- |
| `letsencrypt-production` | `https://acme-v02.api.letsencrypt.org/directory` |
| `letsencrypt-staging` | `https://acme-staging-v02.api.letsencrypt.org/directory` |

### Self-Signed / Internal CA

| Resource | Kind | Details |
| --- | --- | --- |
| `selfsigned-issuer` | `ClusterIssuer` | Bootstrap issuer with no backing CA |
| `home-selfsigned-ca` | `Certificate` | ECDSA P-256 CA cert; org `ewatkins.dev`; secret `root-secret` |
| `home-ca-issuer` | `ClusterIssuer` | CA issuer backed by `root-secret` |
| `strong-selfsigned-ca` | `Certificate` | ECDSA P-384 CA cert; org `ewatkins.dev`; secret `strong-root-secret` |
| `strong-ca-issuer` | `ClusterIssuer` | CA issuer backed by `strong-root-secret` |

## Secret Management

The Cloudflare API token is committed to Git as a SOPS-encrypted secret (`cert-manager-secret.secret.sops.yaml`) encrypted with the cluster's Age key. An `ExternalSecret` definition also exists (`externalsecret.yaml`) but is currently commented out in the kustomization.

## Flux Kustomizations

| Kustomization | Path | Interval | Depends On |
| --- | --- | --- | --- |
| `cert-manager` | `kubernetes/apps/cert-manager/cert-manager/app` | 30m | — |
| `cert-manager-issuers` | `kubernetes/apps/cert-manager/cert-manager/issuers` | 30m | `cert-manager` |

## Links

- [Documentation](https://cert-manager.io/docs/)
- [Helm Chart](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager)
- [GitHub Repository](https://github.com/cert-manager/cert-manager)
