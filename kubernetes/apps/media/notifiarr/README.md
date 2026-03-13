# [Notifiarr](https://notifiarr.com/)

Notifiarr aggregates events and alerts from Sonarr, Radarr, Jellyfin, and other *arr applications and forwards them to Discord and other notification services. It provides a single place to manage all media stack notifications.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Config storage | `notifiarr-config` PVC | Persists API keys, notification rules, and integration settings |
| Media library | NFS `caspian.local:/mnt/user/arrdata` at `/mnt/arrdata` | Allows Notifiarr to read media file details for richer notifications |

## Links

- [Documentation](https://notifiarr.wiki/)
- [GitHub Repository](https://github.com/Notifiarr/notifiarr)
