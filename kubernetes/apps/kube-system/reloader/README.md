# [Reloader](https://github.com/stakater/Reloader)

Reloader watches `ConfigMap` and `Secret` resources for changes and triggers rolling restarts of `Deployment`, `DaemonSet`, and `StatefulSet` workloads that reference them. This ensures applications pick up configuration changes applied via Flux (including SOPS-decrypted secrets) without manual intervention.

## Chart

| Field | Value |
| --- | --- |
| Chart | `stakater/reloader` |
| Version | `2.2.7` |
| Source | HelmRepository `stakater` in `flux-system` |

## Configuration

| Setting | Value |
| --- | --- |
| `fullnameOverride` | `reloader` |
| `readOnlyRootFileSystem` | `true` |
| PodMonitor | enabled, in `kube-system` namespace |

## Usage

Annotate any workload to enable automatic restarts when its referenced ConfigMaps or Secrets change:

```yaml
annotations:
  reloader.stakater.com/auto: "true"
```

Reloader performs a rolling restart (not a full kill) when a referenced object changes, preserving availability. To opt into Reloader's search mode cluster-wide (used by VPA and other components), annotate with `reloader.stakater.com/search: "true"`.

## Links

- [Documentation](https://github.com/stakater/Reloader#readme)
- [Helm Chart](https://github.com/stakater/Reloader/tree/master/deployments/kubernetes/chart/reloader)
- [GitHub Repository](https://github.com/stakater/Reloader)
