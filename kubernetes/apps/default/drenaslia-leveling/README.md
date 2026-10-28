# [Drenaslia Leveling Atlas](https://github.com/ewatkins/drenaslia-leveling)

Leveling guide for every skill in Drenaslia: a single static page served by nginx, with the Keycloak login handled by Envoy Gateway.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/ewatkins/drenaslia-leveling` | Private GHCR package, built by `.github/workflows/image.yaml` in the app repo on every push to `main` (`1.0.<run number>`, `sha-<short>` and `latest` tags) |
| URL | `https://drenaslia.ewatkins.dev` | Internal gateway only |
| Auth | Envoy `SecurityPolicy` OIDC | Client `drenaslia-leveling` on the `master` realm; sign out at `/oauth2/sign_out`. `/drenaslia-levels.user.js` is served by a second route without the login, so Tampermonkey can install and update the userscript. Replaces the oauth2-proxy container used by the repo's docker-compose |
| Secret | Bitwarden entry `drenaslia-leveling-secret` | Synced into `drenaslia-leveling-secret` (OIDC) and `drenaslia-leveling-ghcr` (image pull secret) |

## Bitwarden secret

Create a Secrets Manager entry named `drenaslia-leveling-secret` whose value is JSON:

```json
{
  "OIDC_CLIENT_SECRET": "<from the Keycloak client's Credentials tab>",
  "GHCR_TOKEN": "<GitHub token with read:packages for ewatkins>"
}
```

## Keycloak client

In the `master` realm, create an OpenID Connect client `drenaslia-leveling` with client authentication and the standard flow on, valid redirect URI `https://drenaslia.ewatkins.dev/oauth2/callback` and web origin `https://drenaslia.ewatkins.dev`.

## Updating

Pushing to `main` in the app repo builds a new `1.0.<run number>` image. Renovate (hourly) logs in to ghcr.io with `GHCR_TOKEN` from this app's Bitwarden entry, opens a PR bumping `app/helmrelease.yaml`, and automerges it once Flux Local passes (rule in `.renovate/autoMerge.json5`). The Image Pull check skips this image, since `talosctl image pull` has no pull secret.
