# nodecast-tv

[nodecast-tv](https://github.com/technomancer702/nodecast-tv) is a browser-based player for
Live TV, Movies and Series from an Xtream Codes or M3U provider. Here it is a **front end for
[Dispatcharr](../../dispatcharr/)** — Dispatcharr aggregates and proxies the streams,
nodecast-tv just plays them.

Reachable at `https://nodecast.ewatkins.dev` on the internal gateway.

## Why there is no VPN here

Dispatcharr runs a [gluetun sidecar](../../dispatcharr/app/helmrelease.yaml) and six
internet-facing tools were deliberately moved into its pod to share that tunnel. nodecast-tv
is **not** one of them, and does not need to be:

nodecast-tv has no sources of its own. Everything it fetches — the playlist, the guide, and
every stream segment — comes from `dispatcharr.media.svc.cluster.local`, which is
cluster-internal traffic that never leaves the node. Dispatcharr's own gluetun tunnel already
covers the only hop that touches the public internet.

> This holds **only while every content source points at Dispatcharr**. If you ever add a
> third-party Xtream/M3U provider directly to nodecast-tv, it starts egressing to the internet
> itself and belongs behind a tunnel like everything else in this namespace.

Note that a VPN would not cover browser traffic in any case. With *Force Backend Proxy* off,
the browser fetches streams directly from whatever URL the playlist contains, and no
server-side tunnel touches that.

## First-run setup

1. **Create the Bitwarden item** `nodecast-tv-secret` with one field, `JWT_SECRET`, set to any
   long random string (`openssl rand -hex 32`). [`externalsecret.yaml`](externalsecret.yaml)
   syncs it in, and the pod will not start until it exists. Without it the app falls back to a
   hardcoded constant that is public in the upstream repo — see the comment in that file.
2. **Create the admin user.** First visit shows a setup wizard; auth is mandatory and there is
   no default account.
3. **Add Dispatcharr as a content source** under *Settings → Content Sources*:

   | Type | URL |
   |---|---|
   | M3U | `http://dispatcharr.media.svc.cluster.local:9191/output/m3u` |
   | EPG | `http://dispatcharr.media.svc.cluster.local:9191/output/epg` |

   Then *Refresh Sources*. Both endpoints are unauthenticated. Use the in-cluster Service, not
   `dispatcharr.ewatkins.dev` — the gateway rate-limits, which is what throttled StreamFlow
   (see [../../dispatcharr/tools/README.md](../../dispatcharr/tools/README.md)).

   Xtream Codes works too (`/player_api.php`, with a Dispatcharr username and password) and is
   what enables the Movies and Series sections. Plain M3U gives Live TV only.

4. **Turn on *Force Backend Proxy*.** This is not optional here. Dispatcharr builds the URLs
   inside its M3U from the request's `Host` header, so fetching over the Service returns stream
   URLs like `http://dispatcharr.media.svc.cluster.local:9191/proxy/ts/stream/<uuid>` — an
   address a browser on the LAN cannot resolve. With the backend proxy on, nodecast-tv's server
   fetches them instead and playback works.

## Notes

**Everything is remuxed.** Dispatcharr serves raw MPEG-TS from `/proxy/ts/stream/…`, which no
browser plays natively, so each viewer costs one ffmpeg process piping into the response
(`server/routes/remux.js`). That is why the memory limit is 4 Gi and CPU is left unlimited, and
why [`backendtrafficpolicy.yaml`](backendtrafficpolicy.yaml) disables the request timeout — the
whole viewing session is a single HTTP request.

**Local storage, not NFS.** [`pvc.yaml`](pvc.yaml) uses `openebs-hostpath` rather than the
`nfs-slow` every Dispatcharr tool uses, because `content.db` is opened in SQLite WAL mode and
WAL needs a shared-memory mapping that NFS cannot provide. The tradeoff is that the pod is
pinned to whichever node binds the volume.

**Two databases.** `content.db` (SQLite, the channel/VOD catalogue) and `db.json` (users,
settings, favourites) both live in `/app/data`.

**Hardware transcoding is not wired up.** The image ships VAAPI and QSV drivers and would use
`/dev/dri`, but nothing here mounts it. All remuxing is CPU-only.

**OIDC is available but unused.** The app reads `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`,
`OIDC_CLIENT_SECRET` and `OIDC_CALLBACK_URL`, so it could be pointed at Keycloak the way the
[VPN UI](../../dispatcharr/app/securitypolicy.yaml) is. Its built-in local auth is used instead,
so no Keycloak client is needed.

**Image pinning.** Upstream publishes real semver tags, so Renovate bumps this normally — no
rolling-tag digest tracking like `kptv-fast` and friends.
