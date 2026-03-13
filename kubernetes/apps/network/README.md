# network

This namespace manages external and internal DNS, the Cloudflare tunnel for external access, and the Envoy Gateway ingress controller.

## Apps

- [cloudflare-dns](cloudflare-dns/README.md) - ExternalDNS controller that manages DNS records in Cloudflare
- [cloudflare-tunnel](cloudflare-tunnel/README.md) - Cloudflare tunnel for exposing services externally without open inbound ports
- [envoy-gateway](envoy-gateway/README.md) - Kubernetes Gateway API implementation using Envoy Proxy
- [unifi-dns](unifi-dns/README.md) - ExternalDNS controller that manages DNS records on a UniFi controller
