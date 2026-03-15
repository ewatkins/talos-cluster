# Media

Home media stack covering a media server, photo management, document management, download automation, indexing, and notification tooling. All apps run in the `media` namespace.

Flux error events for all HelmReleases in this namespace are forwarded to Alertmanager at `alertmanager-operated.observability.svc.cluster.local:9093`. The namespace has VolSync privileged movers enabled and Goldilocks VPA recommendations enabled.

## Apps

| App | URL | Description |
| --- | --- | --- |
| [bazarr](bazarr/README.md) | `bazarr.ewatkins.dev` | Automatic subtitle downloader and manager for the media library |
| [immich](immich/README.md) | `photos.ewatkins.dev` | Self-hosted photo and video backup with face recognition and smart search |
| [jellyfin](jellyfin/README.md) | `jellyfin.ewatkins.dev` | Media server for streaming movies, TV shows, and music with Intel GPU transcoding |
| [jellyseerr](jellyseerr/README.md) | `requests.ewatkins.dev`, `media.ewatkins.dev` | Media request portal for Jellyfin, fulfilled automatically by Radarr and Sonarr |
| [notifiarr](notifiarr/README.md) | `notifiarr.ewatkins.dev` | Notification aggregator for the *arr stack, forwarding events to Discord and other services |
| [paperless](paperless/README.md) | `paperless.ewatkins.dev` | Document management system with OCR, Keycloak OIDC authentication, and automated ingestion |
| [prowlarr](prowlarr/README.md) | `prowlarr.ewatkins.dev` | Centralized indexer manager and proxy serving Sonarr and Radarr |
| [radarr](radarr/README.md) | `radarr.ewatkins.dev` | Movie collection manager handling automated acquisition, sorting, and renaming |
| [recommendarr](recommendarr/README.md) | `recommend.ewatkins.dev` | AI-powered recommendation engine suggesting new media based on existing library content |
| [sonarr](sonarr/README.md) | `sonarr.ewatkins.dev` | TV series collection manager handling automated acquisition, sorting, and renaming |

## Shared Infrastructure

All *arr apps (Bazarr, Radarr, Sonarr, Prowlarr, Notifiarr, Jellyfin) mount the same NFS share `caspian.local:/mnt/user/arrdata` for the media library, enabling hardlink-based atomic moves from the download client to the final library location.

All apps use the `bjw-s app-template` Helm chart via an OCI repository in `flux-system`.
