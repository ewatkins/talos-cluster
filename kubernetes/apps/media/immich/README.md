# [Immich](https://immich.app/)

Immich is the self-hosted photo and video backup solution for this cluster. It provides mobile backup, face recognition, album management, and smart search powered by on-cluster machine learning models.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://photos.ewatkins.dev` | Accessible via Envoy Gateway HTTPRoute |
| Database | PostgreSQL via `immich-db-secret` | Stores metadata, albums, users, and ML embeddings |
| Cache | Dragonfly (Redis-compatible) | Job queue and session cache |
| Photo library | NFS `caspian.local:/mnt/user/immich` | Primary storage for original photos and videos |
| ML model cache | OpenEBS hostpath PVC (10Gi) | Persists downloaded face recognition and CLIP models |

The machine learning sidecar runs as a separate container alongside the server and handles face recognition and CLIP embedding generation for smart search.

## Links

- [Documentation](https://immich.app/docs/overview/introduction)
- [GitHub Repository](https://github.com/immich-app/immich)
