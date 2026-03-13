# [Reloader](https://github.com/stakater/Reloader)

Reloader watches `ConfigMap` and `Secret` resources for changes and automatically triggers rolling restarts of `Deployment`, `DaemonSet`, and `StatefulSet` workloads that reference them. This ensures configuration changes applied via Flux (including SOPS-decrypted secrets) are picked up without manual intervention.

## Usage

Annotate any workload to enable automatic restarts when its referenced configs or secrets change:

```yaml
annotations:
  reloader.stakater.com/auto: "true"
```

Reloader will watch all ConfigMaps and Secrets mounted or referenced by that workload. On any change, it performs a rolling restart rather than a full pod kill, preserving availability.

## Links

- [Documentation](https://github.com/stakater/Reloader#readme)
- [Helm Chart](https://github.com/stakater/Reloader/tree/master/deployments/kubernetes/chart/reloader)
- [GitHub Repository](https://github.com/stakater/Reloader)
