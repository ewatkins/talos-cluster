# [Configarr](https://configarr.de/)

Configarr syncs [TRaSH-Guides](https://trash-guides.info/) custom formats, quality profiles and quality definitions into Sonarr and Radarr. It runs as an hourly CronJob; the whole configuration lives in [`app/config/config.yml`](app/config/config.yml), so every profile change is a reviewable commit.

## Managed profiles

| App | Profile | TRaSH trash_id | Quality definition |
| --- | --- | --- | --- |
| Sonarr | `WEB-1080p` (1080p and below, SD fallback) | `72dae194fc92bf828f32cde7744e51a1` | `series` |
| Radarr | `[SQP] SQP-1 (2160p)` | `5128baeb2b081b72126bc8482b2a86a0` | `sqp-streaming` |

Profiles are included with `source: TRASH`, which pulls the profile and its default CF groups directly from the guide. `reset_unmatched_scores` is enabled, so any score not set by TRaSH (or by an override in `config.yml`) is reset to `0`. Unmanaged custom formats are left in place.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/raydak-labs/configarr` | |
| Schedule | `0 * * * *` (`America/Chicago`) | `concurrencyPolicy: Forbid` |
| Sonarr / Radarr | `http://{sonarr,radarr}.media.svc.cluster.local` | In-cluster service, not the gateway |
| Guide repos | `emptyDir` at `/app/repos` | Sparse clone of TRaSH-Guides and recyclarr templates each run |
| Run as user/group | `99:100` | Read-only root filesystem |

## Secrets

`configarr-secret` is built from the existing `notifiarr-secret` Bitwarden item:

| Secret key | Source key | Purpose |
| --- | --- | --- |
| `SONARR_API_KEY` | `DN_SONARR_0_API_KEY` | Sonarr API key (`!env` in `config.yml`) |
| `RADARR_API_KEY` | `DN_RADARR_0_API_KEY` | Radarr API key (`!env` in `config.yml`) |

## Previewing a change

Run a one-off job from the CronJob with `DRY_RUN=true` to print the diff report without touching Sonarr/Radarr:

```bash
kubectl -n media create job configarr-preview --from=cronjob/configarr --dry-run=client -o yaml \
  | yq '.spec.template.spec.containers[0].env += [{"name":"DRY_RUN","value":"true"}]' \
  | kubectl apply -f -
kubectl -n media logs -f job/configarr-preview
kubectl -n media delete job configarr-preview
```

## Links

- [Documentation](https://configarr.de/docs/intro)
- [GitHub Repository](https://github.com/raydak-labs/configarr)
