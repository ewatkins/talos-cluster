# [playit.gg](https://playit.gg)

`playitd` opens an outbound tunnel to playit.gg so players can reach the
Minecraft servers through a playit address instead of the home IP. Players
connect to playit's edge, the agent carries the traffic into the cluster, and
the agent connects on to Velocity on `wing-proxy` (`192.168.50.100:25565`).

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/playit-cloud/playit-agent:1.0.10` (digest-pinned) | Latest non-prerelease |
| Replicas | `1` (Recreate) | One agent per secret key |
| Run as user/group | `65534:65534` (nobody) | Read-only root; `/run/playit` and `/tmp` are emptyDirs |
| Memory limit | `128Mi` | |

There is no metrics endpoint or health port, so there are no probes or
ServiceMonitor.

## Tunnels

Tunnels live in the playit.gg dashboard, not in Git. Each one points at a
local address the agent can reach from the pod network:

| Tunnel | Protocol | Local address |
| --- | --- | --- |
| Minecraft Java | TCP | `192.168.50.100:25565` (Velocity) |
| Minecraft Bedrock | UDP (RakNet) | `192.168.50.100:19132` |

| Edition | Players join | Tunnel address |
| --- | --- | --- |
| Java | `mc.ewatkins.dev` (no port) | `practically-unclog.tun.ply.gg:19087` |
| Bedrock | `mc.ewatkins.dev`, port `63404` | `practically-detected.tun.ply.gg:63404` |

## DNS

`app/dnsendpoint.yaml` publishes `_minecraft._tcp.mc.ewatkins.dev` as an SRV
record pointing at the tunnel, through `cloudflare-dns`. It is an SRV record,
not a CNAME, because playit's free Minecraft Java tunnel resets any handshake
whose hostname isn't the tunnel's own. With SRV, the client sends the SRV
target (`practically-unclog.tun.ply.gg.`) as the hostname, which playit
accepts. `mc.ewatkins.dev:19087` typed directly would be rejected.

Bedrock clients don't read SRV records, so `mc.ewatkins.dev` itself is a
DNS-only CNAME to the Bedrock tunnel and players type its port. RakNet sends no
hostname, so playit can't reject it the way it does for Java. The two records
don't collide: the SRV lives at `_minecraft._tcp.mc`, the CNAME at `mc`.

If a tunnel is ever recreated, its address and port change: update
`app/dnsendpoint.yaml` (and tell Bedrock players the new port).

## Bedrock relay (port 19132)

playit's free tunnel gives Bedrock a random public port (63404). To let
players use `mc.ewatkins.dev` on the default port 19132, a relay VM on Oracle
Cloud's Always Free tier (`bedrock-relay`, `VM.Standard.E2.1.Micro`,
us-chicago-1 AD-2) listens on UDP 19132 and forwards to the Bedrock tunnel
with `socat`. Its network (`relay-vcn`, `relay-subnet`, security list with UDP
19132 open and SSH from home only) was created by hand.

Free Oracle capacity is scarce, so `app/relay-launcher.yaml` is a CronJob that
tries to launch the VM every 10 minutes. It launches only when no
non-terminated instance named `bedrock-relay` exists, so it never makes a
second VM; once the VM exists every run is a no-op that logs its state and
public IP:

```sh
kubectl -n network logs -l job-name --tail=5 --prefix | grep bedrock-relay
```

Once the VM is up: point `mc.ewatkins.dev` at its public IP (an A record here
and in UniFi, replacing the CNAME), move the external Gatus Bedrock check to
`mc.ewatkins.dev:19132`, and delete the CronJob.

## Secrets

`playit-secret` (Bitwarden Secrets Manager via ExternalSecrets) holds the
agent's secret key in its `secret_key` field. `oci-api-secret` holds the Oracle API
key the relay launcher uses (`user`, `tenancy`, `fingerprint`, `region`,
`private_key_b64`). Create the agent on playit.gg
(Docker setup) and copy the key it shows.

## Cutover

1. Check the tunnel address reaches the server.
2. Disable the `Minecraft (Java)` and `Minecraft (Bedrock)` UniFi port
   forwards to `192.168.50.100`. Until then the home IP still serves the
   game directly and the tunnel hides nothing.
3. If VLAN 50 is firewalled from the cluster (see the calagopus README),
   allow the cluster to reach `192.168.50.100` on 25565/tcp and 19132/udp.

Behind the tunnel every player appears to come from the agent's pod IP.
Enable PROXY protocol on the tunnel and in Velocity (`haproxy-protocol =
true`) to keep real client IPs for bans and rate limits; both ends must change
together or logins fail.

## Links

- [GitHub Repository](https://github.com/playit-cloud/playit-agent)
