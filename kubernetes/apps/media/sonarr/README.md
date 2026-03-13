# [Sonarr](https://sonarr.tv/)

Sonarr manages the TV series collection. It monitors configured indexers (via Prowlarr) for new episode releases, automatically grabs and sends them to a download client, then sorts and renames completed downloads into the media library.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `sonarr-config` PVC | Persists library settings, quality profiles, series list, and history |
| Media library | NFS `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata` | Shared NFS mount written to after download completion |

## Links

- [Documentation](https://wiki.servarr.com/sonarr)
- [GitHub Repository](https://github.com/Sonarr/Sonarr)
