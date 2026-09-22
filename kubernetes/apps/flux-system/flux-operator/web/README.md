# Flux Status web UI

The Flux Operator's web UI at `https://flux.ewatkins.dev`, on the internal gateway only.

It runs as its **own release** of the flux-operator chart with `web.serverOnly: true`, and the
UI is switched off in the operator's release (`../app/helmrelease.yaml`). A broken sign-in
config or a missing client secret therefore only affects this deployment, never the operator
that runs Flux. The `flux-web` Flux Kustomization also depends on `external-secrets-stores`,
which the operator itself must not wait on at bootstrap.

## Sign-in

The UI's own OAuth2/OIDC login against Keycloak (`master` realm) — no gateway auth in front.
Signed-in users are **impersonated** into Kubernetes: username from the `email` claim, groups
from the `groups` claim. What they can see or do is decided purely by RBAC:

| Keycloak group | Bound to | Access |
|---|---|---|
| `Flux Admins` | `flux-web-admin` ([`clusterrolebinding.yaml`](clusterrolebinding.yaml)) | everything, including reconcile / suspend / resume |
| anyone else | nothing | signs in, sees nothing |

For read-only access, bind another group to `flux-web-user`.

## Keycloak setup (not in Git)

1. **Client** `flux-web`: OpenID Connect, *Client authentication* on, *Standard flow* on.
   *Valid redirect URIs* `https://flux.ewatkins.dev/oauth2/callback`, *Home URL*
   `https://flux.ewatkins.dev`.
2. **Groups claim**: *Client scopes → flux-web-dedicated → Add mapper → Group Membership*,
   token claim name `groups`, **Full group path off** (otherwise the claim is `/Flux Admins`
   and the binding does not match).
3. **Group** `Flux Admins`, with the admins as members. The name must match the binding
   exactly, including case and the space.

The requested scopes are pinned to `openid profile email` in
[`helmrelease.yaml`](helmrelease.yaml): the UI's defaults also ask for `groups` and
`offline_access`, which Keycloak rejects when the client is not assigned them. The groups
claim comes from the dedicated-scope mapper instead, which is always included.

## Client secret

Bitwarden Secrets Manager item `flux-web-client`, synced by
[`externalsecret.yaml`](externalsecret.yaml). Its value is JSON:

```json
{ "client_id": "flux-web", "client_secret": "<Keycloak → Clients → flux-web → Credentials>" }
```

Until it exists, the `flux-web` HelmRelease fails on the missing `valuesFrom` Secret. That is
harmless: nothing else depends on it.
