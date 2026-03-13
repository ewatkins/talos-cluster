# [Keycloak](https://www.keycloak.org/)

Keycloak is the central identity provider for this cluster. It provides Single Sign-On (SSO) via OIDC for Outline, Paperless-ngx, and Forgejo, with a custom login theme to match the cluster's aesthetic.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://keycloak.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Replicas | 2 | Two instances run behind the gateway; Keycloak uses distributed caching via Infinispan |
| Database | PostgreSQL via `keycloak-db-secret` (JDBC URI) | Stores realms, users, sessions, and client configurations |
| Login theme | Custom (mounted via ConfigMap) | Customized theme applied to the login and registration pages |
| Proxy headers | Forwarded | Required for Keycloak to see correct client IP and protocol when behind Envoy Gateway |

## Integrated Applications

| App | Protocol | Notes |
| --- | --- | --- |
| [Outline](../../default/outline/README.md) | OIDC | `OIDC_DISPLAY_NAME: Keycloak` |
| [Paperless-ngx](../../media/paperless/README.md) | OIDC | `allauth.socialaccount.providers.openid_connect` |
| [Forgejo](../../development/forgejo/README.md) | OIDC | External authentication only |

## Links

- [Documentation](https://www.keycloak.org/documentation)
- [GitHub Repository](https://github.com/keycloak/keycloak)
