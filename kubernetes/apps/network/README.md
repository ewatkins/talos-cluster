# Network

External and internal DNS automation, TLS certificate management, the Cloudflare tunnel for external access, and the Envoy Gateway ingress controller. All apps run in the `network` namespace.

Flux error events for all HelmReleases in this namespace are forwarded to Alertmanager at `alertmanager-operated.observability.svc.cluster.local:9093`. The namespace has VolSync privileged movers enabled and Goldilocks VPA recommendations enabled.

## Apps

| App | Description |
| --- | --- |
| [certificates](certificates/) | Let's Encrypt wildcard TLS certificates for `ewatkins.dev` and `*.ewatkins.dev`, pushed to Bitwarden for cross-namespace use |
| [cloudflare-dns](cloudflare-dns/README.md) | ExternalDNS controller publishing proxied `ewatkins.dev` DNS records to Cloudflare |
| [cloudflare-tunnel](cloudflare-tunnel/README.md) | Outbound-only `cloudflared` tunnel (2 replicas, QUIC + post-quantum) exposing services externally without inbound firewall ports |
| [envoy-gateway](envoy-gateway/README.md) | Kubernetes Gateway API implementation (Envoy Proxy) providing `internal` and `external` Gateways with HTTPRoute-based routing |
| [unifi-dns](unifi-dns/README.md) | ExternalDNS controller publishing local DNS records to a UniFi controller at `https://10.0.0.1` for LAN resolution |

## Certificates

Two cert-manager `Certificate` resources are managed in `kubernetes/apps/network/certificates/app/`:

| Certificate | Issuer | Secret | Covers |
| --- | --- | --- | --- |
| `ewatkins-dev-production` | `letsencrypt-production` (ClusterIssuer) | `ewatkins-dev-production-tls` | `ewatkins.dev`, `*.ewatkins.dev` |
| `ewatkins-dev-staging` | `letsencrypt-staging` (ClusterIssuer) | `ewatkins-dev-staging-tls` | `ewatkins.dev`, `*.ewatkins.dev` |

The production certificate is pushed to Bitwarden Secrets Manager via a `PushSecret` (refreshed every hour) so other namespaces can pull it via ExternalSecrets.

## Traffic Flow

External requests: Cloudflare edge → `cloudflared` tunnel → `envoy-external` service (Cilium LB IP `${EXTERNAL}`) → `external` Gateway → application `HTTPRoute`

Internal requests: LAN client → UniFi DNS (resolves `*.ewatkins.dev` to `internal.ewatkins.dev` CNAME) → `envoy-internal` service (Cilium LB IP `${INTERNAL}`) → `internal` Gateway → application `HTTPRoute`
