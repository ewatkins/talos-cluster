# Actions Runner System

Self-hosted GitHub Actions runners, managed by Actions Runner Controller (ARC). The `talos-cluster` runners have full cluster-admin and Talos OS-level access, enabling CI workflows to perform node upgrades, manifest validation, and cluster operations directly against the live cluster. The `calagopus-anvil` runner builds and tests that extension and has no cluster access.

## Apps

| App | Description |
| --- | --- |
| [actions-runner-controller](actions-runner-controller/README.md) | ARC controller, the `talos-runner` scale set (1–3 replicas) scoped to the `talos-cluster` repo, and the `anvil-runner` scale set (0–1 replicas) scoped to `calagopus-anvil` |
