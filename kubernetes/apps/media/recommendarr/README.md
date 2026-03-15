# [Recommendarr](https://github.com/tannermiddleton/recommendarr)

Recommendarr analyzes the existing Sonarr and Radarr libraries and uses large language models to suggest new TV shows and movies that fit the collection's taste profile.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `docker.io/tannermiddleton/recommendarr:v1.4.4` | |
| URL | `https://recommend.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `3000` | HTTP |
| Secure cookies | Enabled (`FORCE_SECURE_COOKIES=true`) | |
| Data PVC | `recommendarr-data`, 5Gi (`nfs-slow`) | Mounted at `/app/server/data`; persists LLM settings, API connections, and recommendation history |
| Run as user/group | `99:100` | |
| Memory limit | `256Mi` | |

## Links

- [GitHub Repository](https://github.com/tannermiddleton/recommendarr)
