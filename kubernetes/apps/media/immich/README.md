# [Immich](https://immich.app/)

Immich is the self-hosted photo and video backup solution for this cluster. It provides mobile backup, face recognition, album management, and smart search powered by on-cluster machine learning models.

## Components

Immich runs two containers in separate controllers:

| Component | Image | Port |
| --- | --- | --- |
| Server (`immich`) | `ghcr.io/immich-app/immich-server:v2.5.6` | `2283` |
| Machine learning (`machine-learning`) | `ghcr.io/immich-app/immich-machine-learning:v2.5.6` | `3003` |

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://photos.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Media location | `/library` | |
| Trusted proxies | `10.69.0.0/16` | Pod CIDR; allows correct client IP forwarding |
| Database | PostgreSQL via `crunchy-postgres-vector` | `DB_URL` from `immich-db-secret` ExternalSecret; uses `crunchy-postgres-vector-ha.database.svc.cluster.local:5432` |
| Cache / job queue | DragonflyDB `immich-dragonfly.media.svc.cluster.local` | 3 replicas, 512Mi memory limit, emulated cluster mode |
| Photo library | NFS `caspian.local:/mnt/user/immich` | Mounted at `/library` |
| ML model cache | OpenEBS hostpath PVC, 10Gi | Mounted at `/cache` and `/.cache` inside the ML container |
| Server memory limit | `6Gi` | |
| ML memory limit | `4Gi` | |
| Database secret refresh | Every 15 minutes | Via ExternalSecrets from `crunchy-postgres` ClusterSecretStore |

## Links

- [Documentation](https://immich.app/docs/overview/introduction)
- [GitHub Repository](https://github.com/immich-app/immich)
