# [Prowlarr](https://prowlarr.com/)

Prowlarr centralizes indexer management for the *arr stack. Rather than configuring indexers separately in Sonarr and Radarr, Prowlarr manages them in one place and proxies search requests to all downstream applications automatically.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `prowlarr-config` PVC | Persists indexer definitions, API keys, and history |

Prowlarr syncs configured indexers directly to Sonarr and Radarr via their APIs. Add or update indexers in Prowlarr and they propagate automatically.

## Links

- [Documentation](https://wiki.servarr.com/prowlarr)
- [GitHub Repository](https://github.com/Prowlarr/Prowlarr)
