# [cloudflare-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the Cloudflare provider, automatically publishing DNS records for the `ewatkins.dev` zone. It watches `DNSEndpoint` CRD resources created by other applications and keeps the corresponding Cloudflare DNS entries in sync.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Provider | Cloudflare | Records are proxied through Cloudflare for DDoS protection and origin IP masking |
| Sources | `crd` (`DNSEndpoint` only) | Only processes explicit `DNSEndpoint` resources, not Service or Ingress annotations |
| Domain filter | `ewatkins.dev` | Prevents accidental modification of records outside this zone |
| TXT ownership prefix | `k8s.` | Ownership records are prefixed to avoid collision with manually created TXT records |

## Links

- [Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
