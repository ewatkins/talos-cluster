# [Prowlarr](https://prowlarr.com/)

Prowlarr centralizes indexer management for the *arr stack. Rather than configuring indexers separately in Sonarr and Radarr, Prowlarr manages them in one place and syncs them to downstream applications automatically via their APIs.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/home-operations/prowlarr:2.3.3.5296` | |
| URL | `https://prowlarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `80` | HTTP |
| Instance name | `Prowlarr` | |
| Theme | `dark` | |
| Auth method | `External` | Authentication handled upstream (e.g. by the gateway or VPN); disabled for local addresses |
| Update branch | `develop` | |
| DB logging | Disabled | |
| Config PVC | `prowlarr-config`, 5Gi (`nfs-slow`) | Mounted at `/config`; persists indexer definitions and history |
| Run as user/group | `99:100` | |
| Memory limit | `1Gi` | |

## Alerting

Loki alerting rules fire on log patterns indicating database corruption (`database is locked`, `database disk image is malformed`), both at `critical` severity with a 5-minute evaluation window.

## Links

- [Documentation](https://wiki.servarr.com/prowlarr)
- [GitHub Repository](https://github.com/Prowlarr/Prowlarr)
