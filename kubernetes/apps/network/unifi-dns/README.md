# [unifi-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the UniFi webhook provider. It watches Gateway API HTTPRoutes and LoadBalancer Services, then publishes corresponding DNS records to the UniFi controller at `https://10.0.0.1`. This makes cluster services resolvable by hostname on the LAN without relying on split-horizon DNS or manual host entries.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `external-dns` `1.20.0` | OCI mirror at `ghcr.io/home-operations/charts-mirror/external-dns`, verified with cosign |
| Provider | `webhook` | Uses `ghcr.io/kashalls/external-dns-unifi-webhook:v0.8.2` as a sidecar |
| UniFi controller | `https://10.0.0.1` | |
| Sources | `gateway-httproute`, `service` | Publishes records for Gateway API HTTPRoutes and LoadBalancer Services |
| Domain filter | `ewatkins.dev` | Scoped to this zone; records outside it are ignored |
| TXT ownership prefix | `k8s.` | Distinguishes ExternalDNS-managed entries from manually created ones |
| TXT owner ID | `default` | |
| Policy | `sync` | Deletes records no longer present in the cluster |
| Loop trigger | On event | Reconciles immediately when a source resource changes |
| Log level | `debug` | Applied to both the ExternalDNS controller and the webhook sidecar |
| Webhook read/write timeouts | `300s` | |
| Metrics | Prometheus ServiceMonitor enabled | |
| API key refresh | Every 15 minutes | `unifi-dns-secret` from Bitwarden Secrets Manager via ExternalSecrets |

## Links

- [ExternalDNS Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
- [UniFi Webhook Repository](https://github.com/kashalls/external-dns-unifi-webhook)
