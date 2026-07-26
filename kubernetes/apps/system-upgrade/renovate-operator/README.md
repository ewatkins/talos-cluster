# renovate-operator

Runs [Renovate](https://docs.renovatebot.com) inside the cluster via
[mogenius/renovate-operator](https://github.com/mogenius/renovate-operator),
replacing the old `.github/workflows/renovate.yaml` GitHub Action.

Renovate still reads `.renovaterc.json5` and the `.renovate/` presets from the
repo, so update behaviour, grouping and automerge rules are unchanged. Only the
execution environment moved.

## Layout

| Path | Contents |
| --- | --- |
| `app/` | Operator HelmRelease, ExternalSecrets, HTTPRoute |
| `jobs/` | The `RenovateJob` describing what to scan and when |

`jobs/` is a separate Flux Kustomization that `dependsOn` the operator, so the
`RenovateJob` CRD is guaranteed to exist before a `RenovateJob` is created.

## Required setup

This will not reconcile until both of the following exist.

### 1. Bitwarden item

An item named `renovate-operator` containing:

| Key | Value |
| --- | --- |
| `RENOVATE_PRIVATE_KEY` | The GitHub App private key (PEM), base64-encoded |

The manifest applies `b64dec`, matching the convention used by
`actions-runner-system/.../externalsecret.yaml`.

### 2. Flux substitution variables

Added to `kubernetes/flux/vars/cluster-secrets.secret.sops.yaml`, then
`task sops:encrypt`:

| Variable | Value |
| --- | --- |
| `SECRET_RENOVATE_APP_ID` | GitHub App ID (same app as `BOT_APP_ID`) |
| `SECRET_RENOVATE_INSTALLATION_ID` | The app's installation ID for this repo |

Both are consumed by the `GithubAccessToken` generator, which mints a
short-lived installation token so Renovate never holds a long-lived credential.

## UI

Exposed on the internal gateway at `https://renovate.ewatkins.dev`. It has no
authentication configured — the chart supports OIDC (`auth.oidc.*`) against
Keycloak if that is ever wanted.
