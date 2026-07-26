# Dispatcharr Tools

Eleven companion services around [Dispatcharr](../app/), the IPTV channel manager. Each is
its own Flux `Kustomization` in [`../ks.yaml`](../ks.yaml) and every one of them except
`iptv-epg` declares `dependsOn: dispatcharr`.

> **On the URLs below:** which M3U accounts and EPG sources Dispatcharr actually has
> registered lives in Dispatcharr's own Postgres database, not in Git. The URLs given here are
> the integration points each tool exposes — verify the live wiring in the Dispatcharr UI
> under *M3U Accounts* and *EPG Sources*.

They fall into four roles:

| Role | Tools |
|---|---|
| **Feed content in** — Dispatcharr pulls M3U/XMLTV from them | `kptv-fast`, `iptv-epg`, `teamarr`, `webpage-hls` |
| **Curate what's there** — they call the Dispatcharr API | `enhanced-channel-manager`, `epg-matcharr`, `channel-identifiarr`, `streamflow`, `swaparr` |
| **Artwork** | `game-thumbs`, `emby-logos` |
| **Push downstream** | `emby-logos` → Jellyfin |

```mermaid
flowchart LR
    subgraph SRC["Content sources"]
        KPTV["kptv-fast<br/>M3U + XMLTV"]
        IPTV["iptv-epg<br/>XMLTV"]
        TEAM["teamarr<br/>sports XMLTV"]
        HLS["webpage-hls<br/>HLS stream"]
    end

    DISP{{"Dispatcharr :9191"}}

    subgraph CUR["Curation via Dispatcharr API"]
        ECM["enhanced-channel-manager"]
        MATCH["epg-matcharr"]
        IDENT["channel-identifiarr"]
        FLOW["streamflow"]
        SWAP["swaparr"]
    end

    subgraph ART["Artwork"]
        THUMB["game-thumbs"]
        LOGOS["emby-logos"]
    end

    JELLY(["Jellyfin<br/>:8096"])

    KPTV & IPTV & TEAM & HLS -->|pulled by| DISP
    DISP <-->|read + write| ECM & MATCH & IDENT & FLOW & SWAP
    THUMB -.->|thumbnail URLs| TEAM
    DISP -->|channels + logos| JELLY
    LOGOS -->|uploads logo artwork| JELLY
```

## Feeding content into Dispatcharr

### `kptv-fast` — free ad-supported (FAST) channel aggregator

Aggregates public FAST providers into one playlist and one guide. Its UI ("KPTV FAST
Streams") exposes:

- `/playlist` — combined M3U, plus `?provider=` for a single source
- `/epg` and `/epg-gz` — combined XMLTV, likewise filterable
- `/channels`, `/clear_cache`, `/debug`

Providers enabled via `ENABLED_PROVIDERS: all`: plex, pluto, samsung, lg, distrotv, tubi,
xumo, roku, localnow, firetv, git_freetv, git_iptv. A recent build produced **10,466
channels / 408,229 programmes**. `GIT_COUNTRY`/`LG_COUNTRY`/`WHALE_COUNTRY` are pinned to
`us,ca`.

Dispatcharr points at `http://kptv-fast.media.svc.cluster.local:8080/playlist` as an M3U
account and `/epg` as an EPG source. The 6 Gi memory limit is deliberate — building the
combined EPG parses >230 MB of XML in memory and OOMKilled at 1 Gi.

> The `stirr` provider currently 404s upstream (`i.mjh.nz/Stirr/all.xml` is gone). Harmless;
> the other providers still build.

### `iptv-epg` — scraped XMLTV guide

Runs [`iptv-org/epg`](https://github.com/iptv-org/epg) to scrape `zap2it.com` and
`tvguide.com` into `/epg/public/guide.xml`, then serves that directory over pm2 on `:3000`.
Currently **152 channels / 8,814 programmes**.

Dispatcharr points at `http://iptv-epg.media.svc.cluster.local:3000/guide.xml` as an XMLTV
source. Grabs run at **03:00** (`CRON_SCHEDULE`) plus once at boot (`RUN_AT_STARTUP`), and
`strategy: Recreate` prevents two grabs writing `guide.xml` concurrently.

This is the only tool with **no HTTPRoute** — it's cluster-internal, since nothing but
Dispatcharr needs it. `tvtv.us` is unusable from this network (Cloudflare 1020 on every
request), which is why only two sites are enabled.

### `teamarr` — dynamic sports EPG

Self-described as a "Sports EPG generation service". Builds guide data for sports channels
from league/team metadata (**168 mappings across 7 providers and 17 sports**, plus 216 ESPN
soccer leagues cached at startup).

It goes further than a plain source — its API includes `/api/v1/channels/dispatcharr/{id}`,
`/api/v1/channels/managed`, and `/api/v1/channels/reconciliation/*`, so it both generates
EPG *and* manages the Dispatcharr channels it generates for.

Its Dispatcharr connection is configured **in the teamarr UI**, not via env — there is no
`DISPATCHARR_URL` in the HelmRelease. State lives in `teamarr.db` on the `teamarr-data` PVC.

### `webpage-hls` — webpage → HLS transcoder

Runs [`ws4kp-to-hls`](https://github.com/sethwv/ws4kp-to-hls): renders a web page in headless
Chromium and re-encodes the result as an HLS stream, so a website becomes a watchable
channel. Built for [WeatherStar 4000+](https://github.com/netbymatt/ws4kp).

- `/weather?city=…` — the packaged weather channel
- `/stream?url=…` — any arbitrary page (400 without `url`)
- `/health` — liveness (`/` returns 404 **by design**)

It also validates a background music library at startup (66 audio files → a 1,320-track
shared playlist). Dispatcharr ingests the resulting HLS URL as a custom stream. The 2 Gi
limit and the writable `/tmp`, `/streaming-app/cache`, `/home/node/.cache` mounts exist
because of the headless browser.

## Curating what's already in Dispatcharr

### `enhanced-channel-manager` (ECM) — bulk channel operations

The heaviest tool here. Channel pipelines (a rules engine with an evaluator, executor and
rule analyzer), name normalization and abbreviation tags, bandwidth tracking, an M3U change
monitor, backup/restore, and alerting over SMTP/Discord/Telegram.

Ships a **second container**, `enhanced-channel-manager-mcp`, exposing ECM's operations as
MCP tools for LLM agents. It's a sidecar in the same pod, so they talk over localhost
(`MCP_HOST: http://localhost:6101`, `ECM_URL: http://localhost:6100`) rather than the
Service.

All state — `settings.json` (including the Dispatcharr connection), `auth_settings.json`,
`journal.db`, `uploads/`, `tls/` — lives in `CONFIG_DIR=/config` on the
`enhanced-channel-manager-config` PVC. Without that PVC every restart wiped the config and
`m3u_change_monitor` failed on each poll with `URL is missing an 'http://' or 'https://'
protocol`.

### `epg-matcharr` — channel ↔ EPG matching

Matches Dispatcharr channels against available EPG entries, so guide data lands on the right
channel. Reads `DISPATCHARR_URL` from env; the API token is set **through its UI on first
run**. `DISPATCHARR_TOKEN` is deliberately left unset rather than pinned empty, because env
vars take priority over UI settings there.

### `channel-identifiarr` — Gracenote station IDs

Populates Gracenote station IDs (TVG IDs) on Dispatcharr channels — the identifiers most
guide providers key off. `EMBY_URL` is intentionally unset: its Emby logo features don't
apply here, and the station IDs it writes are Emby-independent. SQLite DB at
`/data/channelidentifiarr.db` on the `channel-identifiarr-data` PVC.

### `streamflow` — stream quality checking and auto-assignment

Probes every stream behind a channel with ffmpeg, then reorders or reassigns them by measured
quality. Maintains a "UDI" index of Dispatcharr's channels and streams (last seen: 8
channels, 21,346 streams) and runs an automated stream manager that keeps per-channel
patterns.

Because a single quality-check request runs ffmpeg against many sources, it needs both real
memory (4 Gi limit) and [`backendtrafficpolicy.yaml`](streamflow/backendtrafficpolicy.yaml),
which raises the Envoy request timeout from the 15 s default to **1800 s**.

> Its stored Dispatcharr base URL currently points at the *external* hostname, so it
> authenticates through the gateway and gets rate-limited (`429`, leaving stream-ID fetches
> `401`). `DISPATCHARR_BASE_URL` in the HelmRelease already points at the in-cluster Service —
> the UI-stored value overrides it, so the fix belongs in the StreamFlow UI.

### `swaparr` — live stream override control

A lightweight nginx-served UI titled "Swaparr — Stream Override Control", with a *Live
Streams* view and an *All Channels Browser*. Use it to override, by hand, which stream a
channel is currently serving — the manual counterpart to StreamFlow's automation. Stateless;
all reads and writes go straight to `DISPATCHARR_URL`.

The root filesystem is left writable because nginx-alpine writes to `/etc/nginx/conf.d`,
`/var/cache/nginx` and `/var/run` at startup.

## Artwork

### `game-thumbs` — per-event thumbnail generation

Generates thumbnail artwork for sports events, consumed by URL. Pairs naturally with
`teamarr`: teamarr produces the sports guide entries, game-thumbs supplies matching images.
Rate-limited to 90 requests/minute, with an in-pod `emptyDir` at `/app/.cache`.

Its HTTP surface is unusual — most paths return **444**, but `/health` returns a normal
JSON 200. The HelmRelease comment claiming "444 on every path including /" and the resulting
`tcpSocket` probe are therefore more conservative than necessary; a `/health` httpGet would
work.

### `emby-logos` — push channel logos into Jellyfin

Runs [`emby-logo-tools`](https://github.com/sethwv/emby-logo-tools) on a cron, uploading
`LogoLight` and `LogoLightColor` artwork for Live TV channels so they render properly in
clients. Jellyfin forked from Emby and kept the same API surface, so the tool works unchanged
against `http://jellyfin.media.svc.cluster.local:8096`.

This is the only tool that reaches **Jellyfin instead of Dispatcharr**, and the only one
needing a secret: `JELLYFIN_API_KEY`, pulled from Bitwarden by
[`externalsecret.yaml`](emby-logos/externalsecret.yaml). Jellyfin issues long-lived API keys
(Dashboard → API Keys), so it doesn't expire. Runs as root because upstream writes into the
image at runtime, and has no HTTPRoute — it's a scheduled job with no HTTP endpoint.

## Daily pipeline order

The cron schedules are staggered so each stage runs after its inputs are ready:

| Time | What runs |
|---|---|
| 03:00 | `iptv-epg` grabs guide data; Jellyfin refreshes its XMLTV guide |
| 04:00 | `streamflow` pipeline |
| 05:00 | `emby-logos` uploads channel artwork |

`kptv-fast` is independent, refreshing on its own `CACHE_DURATION` (7200 s) and warming both
cache and EPG at startup. `teamarr` runs its own hourly cron.

## Conventions across these tools

**Where config actually lives.** Only `channel-identifiarr`, `streamflow`, `swaparr` and
`epg-matcharr` get their Dispatcharr URL from env. `teamarr` and `enhanced-channel-manager`
store the whole connection — credentials included — in their own database, set through their
UI. Nothing in Git will reproduce that; it's why ECM needs a PVC.

**Cluster-internal addressing.** Tools should reach Dispatcharr at
`http://dispatcharr.media.svc.cluster.local:9191`, never the external hostname — the gateway
applies rate limits that will throttle a busy tool (see the StreamFlow note above).

**NFS ownership.** The `nfs-slow` storage class presents as `99:100` and can't be chowned
from a container, so every tool with a PVC on it runs with `runAsUser: 99`, `runAsGroup: 100`,
`fsGroup: 100` and `fsGroupChangePolicy: OnRootMismatch` — matching Dispatcharr itself. ECM is
the exception: it runs as root, since its image expects to write files owned by its own
`appuser`.

> A stale NFS handle on one of these volumes surfaces as `unable to open database file` or
> `Stale file handle` while the PVC still reports `Bound`. A pod restart remounts it; the data
> is intact.

**No Gatus checks.** These tools are deliberately unmonitored — Dispatcharr itself keeps its
check. `game-thumbs` (444 on `/`) and `webpage-hls` (404 on `/`) would each have needed a
custom path or status anyway.

**Image pinning.** Everything is pinned by tag *and* digest for Renovate. `iptv-epg`,
`kptv-fast`, `webpage-hls` and `emby-logos` publish no version tags, so they track a rolling
tag by digest.
