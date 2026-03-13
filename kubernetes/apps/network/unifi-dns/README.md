# [unifi-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the UniFi webhook provider, automatically publishing local DNS records to a UniFi controller. This makes cluster services resolvable by name on the LAN without relying on split-horizon DNS or manual host entries.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Provider | UniFi webhook (`external-dns-unifi-webhook`) | Communicates with the UniFi controller at `https://10.0.0.1` |
| Sources | `gateway-httproute`, `service` | Publishes records for Gateway API HTTPRoutes and LoadBalancer Services |
| Domain filter | `ewatkins.dev` | Scoped to this zone; records outside it are ignored |
| TXT ownership prefix | `k8s.` | Distinguishes ExternalDNS-managed entries from manual ones |

## Links

- [ExternalDNS Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [UniFi Webhook Repository](https://github.com/kashalls/external-dns-unifi-webhook)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
