# [Gatus](https://github.com/TwiN/gatus)

Automated developer-oriented status page that monitors endpoints and alerts on failures.

## Configuration

Endpoints can be added in three ways:

1. Directly in the main [config](app/resources/config.yaml)
2. Via a dedicated `ConfigMap` with the label `gatus.io/enabled: "true"`
3. Via a shared [Kustomize component](../../../components/gatus/)

A `k8s-sidecar` init container runs alongside Gatus and watches cluster-wide for ConfigMaps carrying the `gatus.io/enabled` label. When a matching ConfigMap is created, updated, or deleted, the sidecar writes the config into the shared `/config` directory and Gatus picks it up without a restart.

## Adding via ConfigMap

The ConfigMap must have the label `gatus.io/enabled: "true"` to be picked up automatically.

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${APP}-gatus"
  labels:
    gatus.io/enabled: "true"
data:
  config.yaml: |
    endpoints:
      - name: "${APP}"
        group: internal
        url: "https://${GATUS_SUBDOMAIN:-${APP}}.${GATUS_DOMAIN:-default.domain}"
        interval: 1m
        ui:
          hide-hostname: true
          hide-url: true
        conditions:
          - "[STATUS] == ${GATUS_STATUS:-200}"
        alerts:
          - type: pushover
```

## Adding via Kustomize Component

Include one of the following components in the app's `kustomization.yaml`:

- `components/gatus/external` — DNS resolves externally, expects HTTP 200
- `components/gatus/internal` — Internal only, hides URL/hostname
- `components/gatus/guarded` — Verifies the endpoint is _not_ externally accessible

Add the following to `ks.yaml` under `postBuild.substitute` as needed:

| Variable | Description |
| --- | --- |
| `APP` | Application name (usually set via `*app` substitution) |
| `GATUS_SUBDOMAIN` | Override the subdomain if different from the app name |
| `GATUS_PATH` | Health check path, e.g. `/-/healthz` |
| `GATUS_STATUS` | Expected HTTP status code if not `200` |

## Links

- [Documentation](https://gatus.io/docs)
- [GitHub Repository](https://github.com/TwiN/gatus)
- [Helm Chart](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template) (deployed via `app-template`)
