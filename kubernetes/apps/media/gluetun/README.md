# [gluetun](https://github.com/qdm12/gluetun)

A Privado VPN tunnel pinned to the UK, exposed to the rest of the namespace as an **HTTP
proxy**. It exists so UK-geolocked IPTV sources are reachable from Dispatcharr without
putting US sources behind a UK IP.

| Setting | Value |
| --- | --- |
| Image | `docker.io/qmcgaw/gluetun:v3.41.1` |
| Proxy | `http://gluetun.media.svc.cluster.local:8888` |
| UI | `https://gluetun.ewatkins.dev` (`docker.io/scuzza/gluetun-webui`) |
| Provider | Privado, OpenVPN over UDP/1194 |
| Exit | London / Manchester, pinned by hostname |

## Why a Deployment and not a Dispatcharr sidecar

A sidecar shares the pod's network namespace, so *everything* Dispatcharr does would leave
through the UK — including US sources, which would then geoblock. It also couples the two:
changing the exit restarts Dispatcharr and kills every in-flight stream, and a tunnel that
cannot connect keeps the app down.

As its own Deployment, consumers opt in per request by using the proxy. Dispatcharr keeps
its own IP, the VPN can be restarted independently, and other apps in the namespace can use
the same tunnel.

The trade-off is that the routing decision now lives in Dispatcharr's database rather than
in Git — see [Wiring Dispatcharr to it](#wiring-dispatcharr-to-it).

## Exit selection

`SERVER_COUNTRIES: United Kingdom` **does not work** on gluetun v3.41.1. That release builds
its baked-in Privado server list by geolocating each endpoint's IP via ipinfo, and Privado's
UK endpoints sit in Leaseweb/Eweka netblocks, so gluetun files all of them under
*Netherlands / Amsterdam*. The only countries it accepts for Privado are Estonia,
Netherlands and United States — a country filter would be rejected at startup, and an
unfiltered setup would land in the UK roughly 5% of the time.

Gluetun is the outlier. The geo-IP databases streaming services actually use both report
these endpoints as GB:

| Endpoint | IP | ipwho.is | ip-api.com |
| --- | --- | --- | --- |
| `lhr-060…065.vpn.privado.io` | `81.171.74.30`, … | GB / London | GB / London |
| `man-009,010.vpn.privado.io` | `91.148.228.128`, … | GB / Manchester | GB / Manchester |

So [`app/configmap.yaml`](app/configmap.yaml) pins `SERVER_HOSTNAMES` to those eight
endpoints. Gluetun picks one at random per connect.

> **On upgrades:** `SERVER_HOSTNAMES` is validated against the list baked into the image, so
> if a Renovate bump of gluetun drops or renames one of these hostnames, the pod will refuse
> to start. Newer gluetun builds read Privado's
> [official server export](https://privadovpn.com/apps/servers_export.json), where the
> country really is `United Kingdom`; once that lands in a tagged release, switch this back
> to `SERVER_COUNTRIES: United Kingdom` and the fragility goes away.

### Changing the exit without a commit

Gluetun cannot switch servers over its API
([qdm12/gluetun#2473](https://github.com/qdm12/gluetun/issues/2473) is still open), so there
are two levers, neither needing a Git change:

**Roll onto a different UK exit** — the *stop* then *start* buttons at
`gluetun.ewatkins.dev`. Gluetun re-runs server selection on each connect and lands on
another of the eight pinned endpoints. The UI also shows live status, exit IP, city, org
and protocol.

**Move somewhere else entirely** — edit the ConfigMap:

```bash
kubectl -n media edit configmap gluetun-server
# swap SERVER_HOSTNAMES, or use SERVER_COUNTRIES: United States
```

[`app/configmap.yaml`](app/configmap.yaml) carries `kustomize.toolkit.fluxcd.io/ssa:
IfNotPresent`, so Flux creates it once and never overwrites it — the edit sticks, and
Reloader rolls the pod onto the new exit. Confirm what the world sees:

```bash
kubectl -n media exec deploy/gluetun -c ui -- wget -qO- https://ipwho.is
```

To make a change permanent, copy it back into `app/configmap.yaml` and delete the live
ConfigMap so Flux recreates it.

## Wiring Dispatcharr to it

Per-source routing is configured in the Dispatcharr UI, not here:

1. **Settings → Stream Profiles** → add a profile, command `ffmpeg`, and put
   `-http_proxy http://gluetun.media.svc.cluster.local:8888` in the parameters ahead of
   `-i {streamUrl}`.
2. Assign that profile to the **UK M3U account / streams only**. Everything else keeps its
   existing profile and goes out over the normal cluster IP.

Two caveats:

- Dispatcharr's built-in `proxy` stream profile cannot take an HTTP proxy — UK channels have
  to use an ffmpeg-based (or streamlink) profile.
- M3U playlist and XMLTV downloads are performed by Django/Celery and ignore the stream
  profile. If a UK provider geoblocks the *playlist* URL as well as the streams, set
  `HTTP_PROXY`/`HTTPS_PROXY` to the proxy on Dispatcharr's `app` and `celery` containers
  along with `NO_PROXY=.svc.cluster.local,.cluster.local,10.0.0.0/8` — note that this sends
  *all* their outbound fetching through the UK, not just the one provider.

## Networking and security

`FIREWALL_OUTBOUND_SUBNETS` keeps three CIDRs on `eth0` so the pod stays reachable and can
resolve names while the tunnel is up:

| Subnet | Why |
| --- | --- |
| `10.40.0.0/16` | LAN: the nodes, and kubelet probe replies |
| `10.69.0.0/16` | Pod CIDR: Dispatcharr and the Envoy gateway |
| `10.96.0.0/16` | Service CIDR: CoreDNS |

`FIREWALL_INPUT_PORTS` is `8888,3000` — the proxy and the UI. Gluetun's control server on
`:8000` is deliberately left out, so it is reachable only from inside this pod; that is why
it runs with `{"auth":"none"}`. If you ever expose `:8000`, switch it to
`{"auth":"apikey","apikey":"..."}` (generate with `docker run --rm qmcgaw/gluetun genkey`)
and give the UI a matching `GLUETUN_API_KEY` — it sends the key as `X-API-Key`, which is
what gluetun expects.

The proxy itself is unauthenticated and reachable from anywhere in the cluster. It is not
exposed outside it: only the UI has an HTTPRoute. Set `HTTPPROXY_USER`/`HTTPPROXY_PASSWORD`
if that changes.

Notes on the rest of the setup:

- **No probes on the gluetun container.** A readiness probe would pull the whole pod out of
  the Service when the tunnel drops, taking the UI — the thing you reconnect from — down
  with it. Gluetun restarts its own tunnel on health failures, and the kill switch means a
  broken tunnel fails closed rather than leaking.
- **`strategy: Recreate`** — a rolling update would briefly hold two Privado sessions and
  flap the Service between two exit IPs.
- **`NET_ADMIN`** is required. Gluetun creates `/dev/net/tun` itself using the default
  `MKNOD` capability, so no privileged mode or device mount is needed.
- **No `UPDATER_PERIOD`** — v3.41.1's runtime updater re-derives the server list through the
  same IP geolocation that mislabels the UK endpoints. The baked-in list is deterministic
  and the image is digest-pinned.

## Credentials

`gluetun-secret` comes from Bitwarden Secrets Manager under the item of the same name, as
JSON with `OPENVPN_USER` and `OPENVPN_PASSWORD`. These are the **OpenVPN service
credentials** from the Privado dashboard (Manual Configuration), not the website login.
