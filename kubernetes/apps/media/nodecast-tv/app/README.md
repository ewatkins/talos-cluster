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

That is enforced rather than assumed. [`networkpolicy.yaml`](networkpolicy.yaml) permits egress
only to the cluster and to `10.40.0.0/16`, with no rule matching `0.0.0.0/0`, so the public
internet is unreachable from this pod. The only route out is Dispatcharr, and Dispatcharr is
behind the tunnel.

> Cluster destinations are matched with a `namespaceSelector`, not an `ipBlock` on the pod and
> service CIDRs. Cilium resolves in-cluster destinations by identity and applies CIDR rules only
> to entities outside the cluster, so the CIDR form silently blackholes DNS — `EAI_AGAIN` on
> every lookup. The LAN rule stays a CIDR because `10.40.0.0/16` genuinely is external.

This matters because content sources live in `content.db`, configured through the UI, and nothing
in Git constrains them. Before the policy existed, `ifconfig.co` from inside this pod returned the
house ISP address while Dispatcharr returned a UK Privado one; a source pointed at a third-party
provider would have leaked straight out. It now fails to connect instead.

> If you ever *want* a direct third-party provider here, the fix is a gluetun sidecar of its own,
> not a hole in this policy.

Note that no server-side tunnel covers browser traffic. With *Force Backend Proxy* off, the
browser fetches streams directly from whatever URL the playlist contains — which is a second,
independent reason that setting must stay on.

## First-run setup

1. **Create the Bitwarden Secrets Manager secret** named `nodecast-tv-secret`, in the same
   project as every other secret here. Its *value* is a JSON object, because
   [`externalsecret.yaml`](externalsecret.yaml) uses `dataFrom.extract` — a plain string will
   sync but resolve both fields to empty:

   ```json
   {
     "JWT_SECRET": "<openssl rand -hex 32>",
     "OIDC_CLIENT_SECRET": "<Keycloak client secret for `nodecast`>"
   }
   ```

   The pod will not start until this exists.
2. **Create the admin user.** First visit shows a setup wizard; auth is mandatory and there is
   no default account. Do this even if you only intend to use SSO — see below.
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

**"Force Audio Transcode" must be on for AAC channels.** Dispatcharr's streams are h264 + AAC in
MPEG-TS, and the default remux path fails on them:

```
Malformed AAC bitstream detected: use the audio bitstream filter 'aac_adtstoasc' to fix it
Error submitting a packet to the muxer: Operation not permitted
```

MPEG-TS carries AAC in ADTS framing and MP4 needs it as a raw ASC header, which `-bsf:a
aac_adtstoasc` would convert. `remux.js` omits that filter **on purpose** — it breaks AC3, EAC3
and MP3 — and the code comment directs you to `/api/transcode` instead. So this is upstream's
intended behaviour, not a misconfiguration, and no version bump will change it.

Enabling *Settings → Playback → Force Audio Transcode* routes playback through an HLS session
with `videoMode: 'copy'`: video is still stream-copied, only audio is re-encoded to AAC in a
container that accepts it. Cheap — audio-only encoding, no GPU involved. Verified against a live
channel in-pod: the remux command exits 255 on the muxer error, the transcode command exits 0 and
writes valid segments.

**Local storage, not NFS.** [`pvc.yaml`](pvc.yaml) uses `openebs-hostpath` rather than the
`nfs-slow` every Dispatcharr tool uses, because `content.db` is opened in SQLite WAL mode and
WAL needs a shared-memory mapping that NFS cannot provide. The tradeoff is that the pod is
pinned to whichever node binds the volume.

**Two databases.** `content.db` (SQLite, the channel/VOD catalogue) and `db.json` (users,
settings, favourites) both live in `/app/data`.

**No GPU, and it cannot usefully have one.** Unlike
[Jellyfin](../../jellyfin/app/resourceclaimtemplate.yaml) and unmanic, which claim an Intel GPU
over DRA, this app is pinned to a device path it will never find here:
`server/services/transcodeSession.js` hardcodes `-hwaccel_device /dev/dri/renderD128`, while DRA
presents the device as **`renderD129`** on all three GPU nodes. Verified in-container — `ffmpeg
-hwaccel vaapi -hwaccel_device /dev/dri/renderD128` fails with *"No VA display found"*, and the
same command against `renderD129` encodes fine. `addVaapiEncoderArgs` sets no separate
`-vaapi_device`, so decode and encode fail together. Still hardcoded on upstream `main`, so a
version bump will not fix it.

Claiming a GPU anyway would be actively worse: `hwDetect.js` would then report `Recommended
encoder: vaapi`, so choosing **auto** in the transcode settings would select an encoder that
fails, where today it correctly resolves to software.

Little is lost. Normal playback is `/api/remux` running ffmpeg with `-c copy` — a pure container
swap from MPEG-TS to fragmented MP4, no decode, no encode, nothing a GPU accelerates. Only the
opt-in `/api/transcode` path re-encodes, and it falls back to software. If upstream ever makes
the device path configurable, adding a claim is a `ResourceClaimTemplate` plus
`supplementalGroups: [44, 105, 10000]`, copied from Jellyfin.

**The pod runs on tahoe** because that is where the PVC bound, not because anything pins it
there. Since the volume follows first scheduling, moving nodes later means recreating the PVC
and losing the database.

## Keycloak SSO

Wired to the `nodecast` client in the `master` realm — the app's own OIDC support, not an Envoy
`SecurityPolicy` like the [VPN UI](../../dispatcharr/app/securitypolicy.yaml) uses. It has to be
in-app, because the JWT it mints is what the player uses for every subsequent `/api` call.

The client needs redirect URI `https://nodecast.ewatkins.dev/api/auth/oidc/callback` and must be
confidential (client authentication on) — the secret is required, and SSO stays silently
disabled without it. Only `OIDC_ISSUER_URL` is set: `server/auth.js` builds the auth, token and
userinfo endpoints from it using Keycloak's `/protocol/openid-connect/*` layout, which is
exactly what Keycloak serves, so the three explicit URL overrides it also accepts are redundant.

Two things worth knowing:

- **SSO users are provisioned as `viewer`, not `admin`** (`role: 'viewer'` in `configureOidcStrategy`).
  There is no group or role mapping. So keep the local admin account from the setup wizard —
  it's the only way to reach settings and promote anyone.
- **OIDC state lives in an in-memory session store** seeded from `JWT_SECRET`. A pod restart
  mid-login fails that login; retrying works. Harmless at one replica, but it does mean this
  will not survive being scaled out.

**Image pinning.** Upstream publishes real semver tags, so Renovate bumps this normally — no
rolling-tag digest tracking like `kptv-fast` and friends.
