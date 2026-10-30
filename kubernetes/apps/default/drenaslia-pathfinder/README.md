# [Drenaslia Pathfinder](https://github.com/ewatkins/drenaslia-pathfinder)

A planning companion for Drenaslia (skill guides, quest route, items and storage): a static page served by nginx, with the Keycloak login handled by Envoy Gateway.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/ewatkins/drenaslia-pathfinder` | Private GHCR package, built by `.github/workflows/image.yaml` in the app repo when it's run by hand, from `main` (`<year>.<month>.<day>.<run number>` with the America/Chicago date, `sha-<short>` and `latest` tags) |
| URL | `https://pathfinder.ewatkins.dev` | Internal gateway only. The old `https://drenaslia.ewatkins.dev` redirects there (301, path kept), apart from the userscript paths, which it still serves so installs from before the move can update |
| Auth | Envoy `SecurityPolicy` OIDC | Client `drenaslia-pathfinder` on the `master` realm; sign out at `/oauth2/sign_out`. `/drenaslia-pathfinder.user.js` (and the pre-rename `/drenaslia-levels.user.js`) is served by a second route without the login, so Tampermonkey can install and update the userscript. Replaces the oauth2-proxy container used by the repo's docker-compose |
| Secret | Bitwarden entry `drenaslia-leveling-secret` (named before the Pathfinder rename) | Synced into `drenaslia-pathfinder-secret` (OIDC) and `drenaslia-pathfinder-ghcr` (image pull secret) |
| Database | `pathfinder` on the `pg16` cluster, user `pathfinder-admin` | Synced into `drenaslia-pathfinder-db` (`DATABASE_URL`) for the `api` container, which keeps each Keycloak user's saved site data (it creates its own table). The SecurityPolicy forwards the access token, which the API checks itself |

## Bitwarden secret

Create a Secrets Manager entry named `drenaslia-leveling-secret` whose value is JSON:

```json
{
  "OIDC_CLIENT_SECRET": "<from the Keycloak client's Credentials tab>",
  "GHCR_TOKEN": "<GitHub token with read:packages for ewatkins>"
}
```

## Keycloak client

In the `master` realm, create an OpenID Connect client `drenaslia-pathfinder` with client authentication and the standard flow on, valid redirect URI `https://pathfinder.ewatkins.dev/oauth2/callback` and web origin `https://pathfinder.ewatkins.dev`.

## Updating

Running the Build New Image workflow in the app repo (`gh workflow run image.yaml -R ewatkins/drenaslia-pathfinder`, or Run workflow on its Actions tab) builds a new `<year>.<month>.<day>.<run number>` image from `main`; pushes alone don't. Renovate (hourly) logs in to ghcr.io with `GHCR_TOKEN` from this app's Bitwarden entry, opens a PR bumping `app/helmrelease.yaml`, and automerges it once Flux Local passes (rule in `.renovate/autoMerge.json5`). The Image Pull check skips this image, since `talosctl image pull` has no pull secret.
