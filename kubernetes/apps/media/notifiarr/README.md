# [Notifiarr](https://notifiarr.com/)

Notifiarr aggregates events and alerts from the *arr stack and forwards them to Discord and other notification services. It connects directly to Prowlarr, Radarr, Sonarr, and SABnzbd via their APIs.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/notifiarr/notifiarr:v0.9.5` | |
| URL | `https://notifiarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `5454` | HTTP |
| Pod hostname | `notifiarr-talos` | Used for identification in Notifiarr's dashboard |
| Config PVC | `notifiarr-config`, 1Gi (`openebs-hostpath`) | Persists notification rules and integration settings |
| Media library | NFS `storage.ewatkins.dev:/mnt/user/arrdata` | Mounted at `/media`; enables file-level detail in notifications |
| Run as user/group | `568:568` | |
| Memory limit | `1Gi` | |

## Secrets

Secrets are sourced from Bitwarden Secrets Manager via ExternalSecrets (refreshed every 15 minutes):

| Secret key | Purpose |
| --- | --- |
| `DN_API_KEY` | Notifiarr API key |
| `DN_UI_PASSWORD` | Web UI password |
| `DN_PROWLARR_0_*` | Prowlarr name, URL, and API key |
| `DN_RADARR_0_*` | Radarr name, URL, and API key |
| `DN_SONARR_0_*` | Sonarr name, URL, and API key |
| `DN_SABNZBD_0_*` | SABnzbd name, URL, and API key |

## Links

- [Documentation](https://notifiarr.wiki/)
- [GitHub Repository](https://github.com/Notifiarr/notifiarr)
