# [Forgejo](https://forgejo.org/)

Forgejo is the self-hosted Git service for this cluster. It provides repository hosting, issue tracking, pull requests, and CI/CD via Forgejo Actions.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://git.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Authentication | GitHub OAuth2 | Users log in via GitHub; configured as an external auth source in the Forgejo admin panel |
| Registration | Admin-provisioned only | `ALLOW_ONLY_EXTERNAL_REGISTRATION: true` disables the local sign-up form; new account creation via OAuth is also disabled, so accounts must be created by an admin before a user can log in with GitHub |
| OpenID | Disabled | `ENABLE_OPENID_SIGNIN` and `ENABLE_OPENID_SIGNUP` are both `false` |
| Database | PostgreSQL via `forgejo-db` secret | Stores repositories, issues, users, and settings |
| Cache / Queue | Dragonfly (Redis-compatible) | Used for session storage, task queues, and caching |
| Object storage | Minio at `s3.ewatkins.dev:443` | Stores LFS objects, release attachments, and avatars |
| Email | SMTP configured | Sends notifications for issues, PRs, and CI results |
| Metrics | Prometheus ServiceMonitor | Exposes Forgejo application metrics |

## Runners

Forgejo Actions runners execute CI/CD workflows triggered by repository events. Two runner pods run as a StatefulSet (`forgejo-runner-0`, `forgejo-runner-1`) and start in parallel.

### Architecture

Each pod runs two containers side by side:

- **`daemon`** — Docker-in-Docker (`docker:dind`) running as a privileged container. Provides a Docker daemon that workflow steps can use to build and run containers. TLS certs are generated into a shared `emptyDir` at `/certs`.
- **`app`** — The Forgejo runner process. Waits for the Docker daemon on `tcp://localhost:2376` to become ready, then starts polling Forgejo for jobs.

### Registration

An init container (`runner-register`) runs once per pod on first start. It:

1. Checks for `/data/.runner` — if it already exists, registration is skipped (idempotent across restarts)
2. Registers the runner with Forgejo using the token from `forgejo-runner-secret`
3. Generates `config.yml` and patches it to enable host networking, point at the Docker daemon via TLS, and allow volume mounts for Docker certs

The runner name is derived from the pod name (`metadata.name`), so each replica registers as a distinct runner in the Forgejo UI.

### Runner Labels

Labels control which workflow `runs-on` values this runner accepts:

| Label | Container image |
| --- | --- |
| `self-hosted` | Runs directly on the host (no container) |
| `docker` | `ghcr.io/catthehacker/ubuntu:act-22.04` |
| `ubuntu-latest` | `ghcr.io/catthehacker/ubuntu:act-22.04` |
| `ubuntu-22.04` | `ghcr.io/catthehacker/ubuntu:act-22.04` |
| `renovate` | `ghcr.io/catthehacker/ubuntu:act-22.04` |

### Storage

Each replica has a dedicated 128Mi `openebs-hostpath` PVC mounted at `/data`. This stores the `.runner` registration file and the generated `config.yml`, so the runner does not need to re-register after a pod restart.

### Secrets

`forgejo-runner-secret` (ExternalSecret from Bitwarden) provides:

| Key | Purpose |
| --- | --- |
| `RUNNER_TOKEN` | Registration token from the Forgejo admin panel |
| `FORGEJO_INSTANCE_URL` | Forgejo base URL the runner connects to |

## Links

- [Documentation](https://forgejo.org/docs/latest/)
- [Helm Chart](https://codeberg.org/forgejo-contrib/forgejo-helm)
- [GitHub Repository (mirror)](https://github.com/go-gitea/gitea)
