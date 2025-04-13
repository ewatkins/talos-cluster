# [Gatus](https://github.com/TwiN/gatus)

Automated developer-oriented status page

## Config

Adding something to be tracked with Gatus can either be done with adding it as an endpoint in the [config](app/resources/config.yaml), adding a configmap just for gatus, or adding it using the [templates](../../../components/gatus/).

## Configmap

If setting up a specific configmap just for the resource, the configmap should have the label of `gatus.io/enabled: "true"`

Example:

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${APP}-gatus-example"
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

## Templates

A resource can be added using a Template by including one of the following in the Kustomization.

- `templates/gatus/external`
- `templates/gatus/guarded`
- `templates/gatus/internal`

Also, the following postBuild subsitutions should be included in `ks.yaml`

```yaml
postBuild:
  substitute:
```

`APP` - Application name, can be supplied with \*app

`GATUS_SUBDOMAIN` - Alternative subdomain that is not the app name

`GATUS_PATH` - Endpoint to use such as /-/healthz

`GATUS_STATUS` - Alternative status code that should be returned, e.g. 404

### _External_

Resources that should have DNS resolved externally, and should be returning 200 or `GATUS_STATUS`.

### _Guarded_

Checks to make sure that the DNS record does not exist externally. This should only be used if I ONLY care about making sure it's not accessible externally.

### _Internal_

These are things that may or may not be external, but I want to hide the url/hostname and should be returning 200 or `GATUS_STATUS`.

### _Infrastructure_

These are things that support the cluster that I would like to keep an eye on, e.g. Postgres, Internet, Flux
