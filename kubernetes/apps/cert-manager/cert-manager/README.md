# [cert-manager](https://cert-manager.io/)

cert-manager automates the management and issuance of TLS certificates for the cluster. It handles ACME DNS-01 challenges against Cloudflare for `*.ewatkins.dev` certificates and provides a self-signed `ClusterIssuer` for internal services.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| CRD installation | Automatic | CRDs are installed and kept in sync by the Helm chart |
| DNS-01 nameservers | `1.1.1.1`, `9.9.9.9` | Recursive resolvers used to verify challenge propagation |
| Self-signed issuer | `selfsigned` ClusterIssuer | Available cluster-wide for internal certificate needs |
| Metrics | Prometheus ServiceMonitor | Exposes certificate expiry and renewal metrics |

## Links

- [Documentation](https://cert-manager.io/docs/)
- [Helm Chart](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager)
- [GitHub Repository](https://github.com/cert-manager/cert-manager)
