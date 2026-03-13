# [Bazarr](https://www.bazarr.media/)

Bazarr automatically downloads and manages subtitles for the media library, working alongside Sonarr and Radarr to keep subtitle files in sync with new and existing content.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `bazarr-config` PVC at `/config` | Persists subtitle settings, provider credentials, and history |
| Media library | NFS `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata` | Shared NFS mount used by all *arr applications |

## Links

- [Documentation](https://wiki.bazarr.media/)
- [GitHub Repository](https://github.com/morpheus65535/bazarr)
