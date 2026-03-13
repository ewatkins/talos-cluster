# flux-system

The Flux CD GitOps engine and its supporting configuration. Flux watches `kubernetes/apps/` and reconciles cluster state from Git every 30 minutes, with immediate reconciliation triggered via GitHub webhooks.

## Apps

| App | Description |
| --- | --- |
| [flux-operator](flux-operator/README.md) | Kubernetes operator that manages the Flux CD installation lifecycle |
| [flux-instance](flux-instance/README.md) | `FluxInstance` resource declaring the desired Flux distribution and components |
| [addons](addons/README.md) | Prometheus monitoring, GitHub commit status notifications, and webhook receivers |
