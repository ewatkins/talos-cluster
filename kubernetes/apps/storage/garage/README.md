# [Garage](https://garagehq.deuxfleurs.fr/)

Garage is a lightweight, distributed S3-compatible object store. It is deployed as a single-node instance with a separate web management UI. The web UI is protected by Keycloak OIDC via an Envoy Gateway SecurityPolicy.

## Components

| Component | Description |
| --- | --- |
| `garage` | Core Garage server (S3 API + admin API) |
| `garage-webui` | Web management UI (`khairul169/garage-webui`) |

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `dxflrs/garage:v2.2.0` | |
| Chart | `app-template` (OCI) from `flux-system` | Both components use `app-template` |
| S3 API endpoint | `https://s3-garage.ewatkins.dev` (port 3900) | Internal gateway; DNS via `internal.ewatkins.dev` |
| S3 region | `us-east-1` | |
| S3 root domain | `.s3-garage.ewatkins.dev` | Used for virtual-hosted bucket access |
| Admin API port | 3903 | Internal only |
| RPC port | 3901 | Bind `[::]:3901`; public addr `127.0.0.1:3901` |
| DB engine | `lmdb` | |
| Replication factor | 1 | Single-node deployment |
| Compression level | 2 | |
| Metadata snapshot interval | 6h | |
| Data PVC | `garage-data`, 20Gi, `ReadWriteOnce` | StorageClass `nfs-slow` |
| Metadata PVC | `garage-meta`, 512Mi, `ReadWriteOnce` | StorageClass `openebs-hostpath` |
| Resources (garage) | requests: 100m CPU; limits: 1Gi memory | |
| Security context | `runAsUser: 1000`, `runAsNonRoot: true`, `readOnlyRootFilesystem: true` | |

## Web UI

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `khairul169/garage-webui:1.1.0` | |
| URL | `https://garage.ewatkins.dev` (port 3909) | Internal gateway |
| API base URL | `http://garage.storage.svc.cluster.local:3903` | Connects to Garage admin API in-cluster |
| S3 endpoint | `http://garage.storage.svc.cluster.local:3900` | Connects to Garage S3 API in-cluster |
| Auth | Keycloak OIDC via Envoy SecurityPolicy | Client ID `garage-webui`; issuer `https://keycloak.ewatkins.dev/realms/master`; redirect `https://garage.ewatkins.dev/oauth2/callback` |
| Resources | requests: 10m CPU; limits: 128Mi memory | |

## Secrets

| Secret | Source | Contents |
| --- | --- | --- |
| `garage-secret` | Bitwarden Secrets Manager | `GARAGE_RPC_SECRET`, `GARAGE_ADMIN_TOKEN`, `GARAGE_METRICS_TOKEN`, `client-secret` (OIDC) |

## Flux Dependencies

The `garage-webui` Kustomization `dependsOn` the `garage` Kustomization.

## Health Monitoring

Gatus monitors `https://s3-garage.ewatkins.dev` every 1 minute, expecting HTTP 403 (unauthenticated access to the S3 endpoint).

## Links

- [Documentation](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
- [GitHub Repository](https://git.deuxfleurs.fr/Deuxfleurs/garage)
- [garage-webui](https://github.com/khairul169/garage-webui)
