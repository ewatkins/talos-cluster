# [Keycloak](https://www.keycloak.org/)

Keycloak is an open-source Identity and Access Management solution that provides Single Sign-On (SSO), OIDC, and SAML support. It is used as the central identity provider for cluster applications including Outline, Paperless, and Forgejo.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `keycloak` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `quay.io/keycloak/keycloak` v26.5.5
- Deployed via `bjw-s/app-template` (OCI)
- Accessible at `https://keycloak.ewatkins.dev`
- Runs 2 replicas backed by PostgreSQL (JDBC URI from `keycloak-db-secret`)
- Custom login theme applied via ConfigMap mounts
- Proxy headers forwarding enabled for use behind an ingress/gateway

## Links

- [Documentation](https://www.keycloak.org/documentation)
- [GitHub Repository](https://github.com/keycloak/keycloak)
