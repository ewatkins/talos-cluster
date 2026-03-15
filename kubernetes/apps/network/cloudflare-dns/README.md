# [cloudflare-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the Cloudflare provider. It watches `DNSEndpoint` CRD resources and keeps the corresponding DNS entries in the `ewatkins.dev` Cloudflare zone in sync. All records are created as Cloudflare-proxied (orange-cloud).

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `external-dns` `1.20.0` | OCI mirror at `ghcr.io/home-operations/charts-mirror/external-dns`, verified with cosign |
| Provider | `cloudflare` | Records proxied via Cloudflare (`--cloudflare-proxied`) |
| Sources | `crd` (`DNSEndpoint` only) | Does not watch Services or Ingresses; requires explicit `DNSEndpoint` resources |
| Domain filter | `ewatkins.dev` | Scoped to a single zone via `--zone-id-filter` |
| Records per page | `1000` | `--cloudflare-dns-records-per-page=1000` |
| TXT ownership prefix | `k8s.` | Distinguishes ExternalDNS-managed TXT records from manually created ones |
| TXT owner ID | `default` | |
| Policy | `sync` | Deletes records no longer present in the cluster |
| Loop trigger | On event | Reconciles immediately when a `DNSEndpoint` changes |
| Metrics | Prometheus ServiceMonitor enabled | |
| Credentials refresh | Every 15 minutes | `cloudflare-dns-secret` from Bitwarden Secrets Manager via ExternalSecrets |

## Alerting

PrometheusRules fire at `critical` severity (5-minute window) for registry errors, source errors, apply-changes errors, and record-gathering errors.

## Links

- [Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
- [Helm Chart](https://github.com/home-operations/charts-mirror)
