# [Pulse](https://github.com/rcourtman/Pulse)

Real-time monitoring dashboard for Proxmox VE infrastructure. Displays node, VM, and container metrics with alerting and webhook support.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://pulse.ewatkins.dev` | Public OIDC redirect target |
| Port | 7655 | Unified frontend + backend port |
| Service type | LoadBalancer | Dedicated IP assigned via Cilium LB IPAM (`${PULSE}` variable) |
| Authentication | OIDC (`preferred_username` claim) | Proxied through Keycloak |
| Persistence | PVC `pulse-data` mounted at `/data` | Stores configuration and state |
| Credentials | `pulse-secret` (ExternalSecret from Bitwarden) | Proxmox API token and OIDC client secret |
| Node agent | `pulse-agent` DaemonSet | Host agent per Talos node for disk usage (qemu-guest-agent returns no fsinfo on Talos); token `PULSE_AGENT_TOKEN` (`agent:report` scope) |

## Links

- [GitHub Repository](https://github.com/rcourtman/Pulse)
