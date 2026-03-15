# cert-manager

Automated TLS certificate lifecycle management for the cluster, issuing and renewing certificates from ACME (Let's Encrypt via Cloudflare DNS-01) and self-signed CA issuers.

Flux alerts for this namespace are routed to Alertmanager at `alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [cert-manager](cert-manager/README.md) | Kubernetes certificate operator handling ACME DNS-01 challenges against Cloudflare and self-signed CA issuers |
