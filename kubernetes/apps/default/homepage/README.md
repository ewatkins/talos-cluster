# [Homepage](https://github.com/gethomepage/homepage)

A modern, fully static, fast dashboard with integrations for over 100 services.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/gethomepage/homepage:v1.13.2` | |
| URL | `https://homepage.ewatkins.dev` | Internal gateway only; `HOMEPAGE_ALLOWED_HOSTS` must match |
| Config | `homepage-config` ConfigMap | Each file mounted into `/app/config`; Reloader restarts on change |
| Kubernetes mode | `cluster` with `gateway: true` | Cluster/node widgets + HTTPRoute service discovery |
| RBAC | ClusterRole `homepage` | Read nodes, pods, namespaces, ingresses, HTTPRoutes, metrics |

## Service discovery

Homepage auto-discovers HTTPRoutes annotated with:

```yaml
gethomepage.dev/enabled: "true"
gethomepage.dev/name: "My App"
gethomepage.dev/description: "Does a thing"
gethomepage.dev/group: "Apps"
gethomepage.dev/icon: "mdi-application"
```

Static entries live in `services.yaml` in the ConfigMap.

## Links

- [Docs](https://gethomepage.dev)
- [GitHub Repository](https://github.com/gethomepage/homepage)
