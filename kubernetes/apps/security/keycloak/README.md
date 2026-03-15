# [Keycloak](https://www.keycloak.org/)

Keycloak is the central identity provider for this cluster. It provides Single Sign-On (SSO) via OIDC for Outline, Paperless-ngx, and Forgejo. It runs with a custom login theme that overrides the default Keycloak UI with a dark frosted-glass design served from a ConfigMap.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `quay.io/keycloak/keycloak:26.5.5` | Official Keycloak image |
| Chart | `app-template 4.6.2` via `oci://ghcr.io/bjw-s-labs/helm/app-template` | |
| Replicas | 2 | Rolling update with max 1 unavailable |
| Hostname | `https://keycloak.ewatkins.dev` | Also accessible at `auth.ewatkins.dev` |
| DNS | CNAME to Cloudflare Tunnel (`cfargotunnel.com`) | Publicly accessible via Cloudflare Tunnel |
| Routing | External gateway HTTPRoute | HSTS header set (`max-age=31449600; includeSubDomains`) |
| Database | PostgreSQL | JDBC URI sourced from `keycloak-db-secret` (crunchy-postgres user `keycloak-admin`) |
| Admin credentials | `keycloak-admin-secret` | Sourced from Bitwarden Secrets Manager |
| Proxy headers | `xforwarded` | Required behind Envoy Gateway; trusted pod CIDR `10.69.0.0/16` |
| HTTP port | 8080 | Service exposes port 80 → container port 8080 |
| Health/management port | 9000 | Used for startup, readiness, and liveness probes |
| Login theme | `ewatkins` (custom) | Mounted from `keycloak-theme` ConfigMap into `/opt/keycloak/themes/ewatkins/login` |
| Theme caching | Disabled | `KC_SPI_THEME_CACHE_THEMES=false`, `KC_SPI_THEME_STATIC_MAX_AGE=-1` |
| Resources | requests: 100m CPU, 666Mi memory; limits: 2048Mi memory | |

## Secrets

| Secret | Source | Contents |
| --- | --- | --- |
| `keycloak-admin-secret` | Bitwarden Secrets Manager | Bootstrap admin password (`KC_ADMIN_PASSWORD`) |
| `keycloak-db-secret` | crunchy-postgres ClusterSecretStore | JDBC URI for PostgreSQL user `keycloak-admin` |

## Custom Theme

The `keycloak-theme` ConfigMap provides three files mounted into the `ewatkins` login theme directory:

| File | Mount path |
| --- | --- |
| `theme.properties` | `/opt/keycloak/themes/ewatkins/login/theme.properties` |
| `login.css` | `/opt/keycloak/themes/ewatkins/login/resources/css/login.css` |
| `messages_en.properties` | `/opt/keycloak/themes/ewatkins/login/messages/messages_en.properties` |

The theme inherits from the default `keycloak` parent, hides the username/password form in favor of social provider buttons (GitHub and Google), and applies a dark frosted-glass card with a forest background image.

## Integrated Applications

| App | Protocol | Notes |
| --- | --- | --- |
| [Outline](../../default/outline/README.md) | OIDC | `OIDC_DISPLAY_NAME: Keycloak` |
| [Paperless-ngx](../../media/paperless/README.md) | OIDC | `allauth.socialaccount.providers.openid_connect` |
| [Forgejo](../../development/forgejo/README.md) | OIDC | External authentication only |
| [Garage Web UI](../../storage/garage/README.md) | OIDC (Envoy SecurityPolicy) | Client ID `garage-webui`, issuer `https://keycloak.ewatkins.dev/realms/master` |

## Flux Dependencies

The Keycloak Kustomization `dependsOn` the `crunchy-postgres-operator-cluster` Kustomization so the database is available before Keycloak starts.

## Links

- [Documentation](https://www.keycloak.org/documentation)
- [GitHub Repository](https://github.com/keycloak/keycloak)
- [Helm Chart (app-template)](https://github.com/bjw-s-labs/helm-charts)
