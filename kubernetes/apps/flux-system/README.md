# flux-system

This namespace contains the Flux CD GitOps engine and its supporting configuration, including the operator, the cluster instance definition, and add-ons for monitoring and webhook delivery.

## Apps

- [flux-operator](flux-operator/README.md) - Flux Operator that manages the Flux CD installation lifecycle
- [flux-instance](flux-instance/README.md) - The `FluxInstance` resource that declares the desired Flux distribution and components
- [addons](addons/README.md) - Flux add-ons: Prometheus monitoring, GitHub notifications, and webhook receivers
