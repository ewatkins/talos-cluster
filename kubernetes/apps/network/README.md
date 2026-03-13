# Network

External and internal DNS automation, the Cloudflare tunnel for external access, and the Envoy Gateway ingress controller.

## Apps

| App | Description |
| --- | --- |
| [cloudflare-dns](cloudflare-dns/README.md) | ExternalDNS controller publishing proxied `ewatkins.dev` DNS records to Cloudflare |
| [cloudflare-tunnel](cloudflare-tunnel/README.md) | Outbound-only Cloudflare tunnel exposing services externally without inbound firewall ports |
| [envoy-gateway](envoy-gateway/README.md) | Kubernetes Gateway API implementation (Envoy Proxy) providing HTTPRoute-based routing |
| [unifi-dns](unifi-dns/README.md) | ExternalDNS controller publishing local DNS records to a UniFi controller for LAN resolution |
