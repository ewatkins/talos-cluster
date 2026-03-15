# Actions Runner System

Self-hosted GitHub Actions runners for the `talos-cluster` repository, managed by Actions Runner Controller (ARC). Runners have full cluster-admin and Talos OS-level access, enabling CI workflows to perform node upgrades, manifest validation, and cluster operations directly against the live cluster.

## Apps

| App | Description |
| --- | --- |
| [actions-runner-controller](actions-runner-controller/README.md) | ARC controller and `talos-runner` scale set (1–3 replicas) scoped to the `talos-cluster` repo |
