# [Cantinarr](https://github.com/windoze95/cantinarr)

**On trial.** Cantinarr is a Seerr-style request portal that also covers books: users
browse and request ebooks and audiobooks, and requests are fulfilled by
[Chaptarr](../chaptarr/README.md), the same way Seerr hands movies and series to
Radarr and Sonarr. Seerr itself has no Readarr/Chaptarr support. Cantinarr can
also front Radarr, Sonarr and Lidarr, but Seerr stays the video portal while this
is being evaluated.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/windoze95/cantinarr:1.0.1` | Upstream tags have no `v` prefix; `latest` / `edge` channels not used |
| URL | `https://cantinarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `8585` | Service exposes it on `80` |
| Config PVC | `cantinarr-config`, 5Gi (`nfs-slow`) | `/config`: SQLite database plus the generated JWT and encryption keys |
| Run as user/group | `99:100` | Started non-root directly; the entrypoint's `PUID` path is unused |
| Replicas | 1, `Recreate` | SQLite and process-local auth/pairing state: never two pods |

The JWT secret and the credential encryption key are generated on first boot and
kept in `/config`, so there is no Bitwarden item. Losing the PVC loses both, and
with them every stored service credential.

## Environment

| Variable | Value | Why |
| --- | --- | --- |
| `CANTINARR_ARR_CALLBACK_URL` | `http://cantinarr.media.svc.cluster.local` | Origin the *arr apps call back to for instant request updates |
| `CANTINARR_DISABLE_UPDATE_CHECK` | `true` | Renovate owns upgrades |
| `CANTINARR_PUSH_GATEWAY_URL` | unset | Push is off; enabling it routes notifications through the third-party relay `push.cantinarr.com` |
| `HOME` | `/config` | The entrypoint only sets it on its root → `PUID` path |

`enableServiceLinks` is off: a Service named `cantinarr` would otherwise inject
`CANTINARR_PORT=tcp://…` and `CANTINARR_SERVICE_*` into the app's own variable
namespace. Upstream detects and ignores the service-link form, but there is no
reason to rely on it.

Not configured: AI features (bundled Codex helper; included-AI is opt-in per user),
MCP (`CANTINARR_OAUTH_ISSUER`), completed-file downloads (`CANTINARR_MEDIA_ROOTS`,
needs media mounts).

## App setup

Done in the UI, stored in the database:

| Area | Setting |
| --- | --- |
| Chaptarr instance | `http://chaptarr.media.svc.cluster.local` + Chaptarr API key |
| Instant updates | Enable on the Chaptarr instance; Chaptarr calls the callback URL above |
| External Address | `https://cantinarr.ewatkins.dev` (connect links and OIDC) |
| SSO | Keycloak client `cantinarr` in the `master` realm, issuer `https://keycloak.ewatkins.dev/realms/master` |

Root folders are not set in Cantinarr. Each book request reads Chaptarr's root
folders over its API and picks, per format, the folder Chaptarr marks as the
effective default eBook/audiobook folder, falling back to a folder flagged for
that format. If none matches, or two are both default, the request fails asking
for "a download folder" — fix it in Chaptarr (Settings → Media Management → Root
Folders), not here.

The instance editor's **Media downloads** section ("No server media folders are
available… set CANTINARR_MEDIA_ROOTS") is the optional completed-file download
feature, not request routing. It stays **Off**: BookOrbit is where books are read
and downloaded.

Use **Test Connection** inside Cantinarr; it runs from the server, which is the
connection that matters.

Reading happens in [BookOrbit](../bookorbit/README.md). Cantinarr's playback links
only know Jellyfin, Plex, Emby and Audiobookshelf, so a fulfilled book request
does not link through to BookOrbit.

## Links

- [GitHub Repository](https://github.com/windoze95/cantinarr)
- [Documentation](https://docs.cantinarr.com)
