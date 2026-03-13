# [Radarr](https://radarr.video/)

Radarr manages the movie collection. It monitors configured indexers (via Prowlarr) for new releases, automatically grabs and sends them to a download client, then sorts and renames completed downloads into the media library.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `radarr-config` PVC | Persists library settings, quality profiles, and history |
| Media library | NFS `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata` | Shared NFS mount written to after download completion |

## Links

- [Documentation](https://wiki.servarr.com/radarr)
- [GitHub Repository](https://github.com/Radarr/Radarr)
