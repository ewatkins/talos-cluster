# Minecraft relay (Oracle Cloud)

Players join `mc.ewatkins.dev` on the default ports (Java 25565, Bedrock
19132; Bedrock's NetherNet also uses TCP 19132 and UDP 19133). That name points at a small Oracle Cloud VM, `minecraft-relay`, which
forwards both editions home through port forwards that accept only the VM.
Players never see the home IP.


```
player ─▶ mc.ewatkins.dev (A 170.9.242.78, DNS-only)
       ─▶ minecraft-relay: HAProxy tcp/25565 and tcp/19132, bedrock-relay.py udp/19132 (all PROXY v2)
                           bedrock-relay.py udp/19133 (no PROXY header)
       ─▶ home WAN IP ─▶ ISP modem (192.168.0.1) ─▶ UniFi (WAN 192.168.0.2)
       ─▶ wing-proxy 192.168.50.100: Velocity (Java), Geyser (Bedrock)
```

## Relay VM

| | |
| --- | --- |
| Instance | `minecraft-relay`, us-chicago-1 AD-1, `VM.Standard.A1.Flex` 1 OCPU / 6 GB (ARM), Ubuntu 24.04 Minimal |
| Public IP | `170.9.242.78`, a reserved public IP also named `minecraft-relay`, so it outlives the VM |
| Network | `relay-vcn` / `relay-subnet`, OpenTofu in `terraform/oracle-relay` (security list: TCP 25565, TCP 19132, UDP 19132 and UDP 19133 from anywhere, SSH from home only, ICMP fragmentation-needed) |
| Java | `haproxy.service`: TCP 25565 to the home WAN IP, `send-proxy-v2` |
| Bedrock (RakNet) | `bedrock-relay.service`: `bedrock-relay.py`, UDP 19132 to the home WAN IP, PROXY v2 header on each client's first packet |
| Bedrock (NetherNet) | `haproxy.service` frontend `minecraft_signaling`: TCP 19132 to the home WAN IP, `send-proxy-v2`. `bedrock-webrtc-relay.service`: the same `bedrock-relay.py` with `PROXY_HEADER=0`, UDP 19133 to the home WAN IP |
| SSH | `ewatkins@170.9.242.78` (key-only, passwordless sudo), from the home IP or the extra sources in `ssh_extra_cidrs` (`oci-api-secret`); from elsewhere jump through a wing, e.g. `-J ewatkins@192.168.50.100` |

us-chicago-1 offers no `VM.Standard.E2.1.Micro`, hence A1.Flex, inside the
Always Free 4 OCPU / 24 GB allowance. Oracle's network-level DDoS protection
covers the VM's address; there is nothing at the application layer.

## Home side

| Hop | Rule |
| --- | --- |
| ISP modem | TCP 25565, TCP+UDP 19132 and UDP 19133 → UniFi WAN `192.168.0.2` |
| UniFi | `Minecraft (Java) from Oracle relay` TCP 25565, `Minecraft (Bedrock) from Oracle relay` TCP+UDP 19132 and `Minecraft (NetherNet) from Oracle relay` UDP 19133 → `192.168.50.100`, source `170.9.242.78` only |
| Panel | The Velocity server has allocations `192.168.50.100:19132` and `192.168.50.100:19133` (Wings publishes each for TCP and UDP) |
| Velocity | `haproxy-protocol = true` in `velocity.toml` on wing-proxy (panel-managed file, not in Git) |

Velocity drops any Java connection that doesn't start with a PROXY header,
so everything that reaches it on 25565 must send one. That includes Geyser's
own connection for Bedrock players: Geyser runs with
`advanced.java.use-haproxy-protocol: true` and `use-direct-connection: false`
(its in-process direct connection sends no header, and Velocity ends it with
"End of stream"). The relay sends v2. The
in-cluster Gatus `velocity` check sends a v1 line
(`default/calagopus/app/gatus.yaml`). Geyser works the same way for Bedrock
(`advanced.bedrock.use-haproxy-protocol` and `haproxy-protocol-whitelisted-ips`
in its config on wing-proxy, also not in Git): the relay's `bedrock-relay.py`
puts a PROXY v2 header on each client's first packet, and the Gatus
`velocity-bedrock` check sends one too. Packets from anyone else are ignored.

NetherNet is the exception. Geyser reads the PROXY header on signaling
(TCP 19132) but not yet on WebRTC gameplay (UDP 19133), so the relay sends
that port on without one, and Geyser sees every NetherNet player as
`170.9.242.78`. Signaling tells the client where to send gameplay, so Geyser
must advertise the relay, not the home or LAN address
(`signaling.builtin.advertise-addresses`). When Geyser adds PROXY support for
WebRTC, set `PROXY_HEADER=1` on `bedrock-webrtc-relay.service`.

## NetherNet (Bedrock 26.60, 2026-10-27)

Bedrock 26.60, planned for October 27th, 2026, stops connecting over RakNet
([GeyserMC blog](https://geysermc.org/blog/preparing-for-nethernet)). Clients
then take a signaling request over TCP (built-in signaling, on the Bedrock
port) and play over WebRTC on UDP. Geyser runs `transport: both`, so clients
older than 26.50 keep using RakNet on UDP 19132 until GeyserMC drops it.

Geyser config (`plugins/Geyser-Velocity/config.yml` on wing-proxy, not in Git):

```yaml
bedrock:
  port: 19132          # RakNet (UDP) and built-in signaling (TCP)
  webrtc-port: 19133   # NetherNet gameplay (UDP); must differ from port with "both"
  transport: both
  signaling:
    mode: builtin
    builtin:
      advertise-addresses: ["170.9.242.78:19133"]
```

Signaling runs over plain HTTP, so on their first join players see a "Trust
on First Use?" prompt. To remove it, serve signaling over HTTPS with a
certificate for `mc.ewatkins.dev` (`signaling.builtin.https`). Geyser reads
the certificate only at startup.

Rollout:

1. Merge: OpenTofu opens TCP 19132 and UDP 19133 in the security list. The
   cloud-init change only affects a rebuilt VM.
2. On the running VM: install the new `haproxy.cfg`, the updated
   `bedrock-relay.py` and `bedrock-webrtc-relay.service` from
   `app/relay-launcher.yaml` (with the home WAN IP filled in), add the two
   `iptables` rules, `netfilter-persistent save`, then enable the new service
   and reload HAProxy.
3. Panel: add the `192.168.50.100:19133` allocation to the Velocity server.
4. ISP modem and UniFi: forward TCP 19132 and UDP 19133, source
   `170.9.242.78` only on UniFi.
5. Geyser: set the config above and restart Velocity. The console should
   print `Built-in signaling started on http://`.
6. Test from a 26.50+ client on `mc.ewatkins.dev`, from outside and on the
   LAN, then confirm a RakNet client still joins. The relay log shows
   NetherNet sessions with backend `geyser-webrtc/home`.

If the home WAN IP changes, update `ssh_source_cidr` in `oci-api-secret`
(Bitwarden) and the two relay services on the VM.

## DNS

`app/dnsendpoint.yaml` publishes `mc.ewatkins.dev` as a DNS-only A record for
the reserved IP, through `cloudflare-dns`. UniFi has a matching local record
for LAN clients, so LAN players take the same path and get the same PROXY
handling.

## Monitoring

The external Gatus on the GCP `uptime` VM (`/opt/gatus`, not in Git) checks
`mc.ewatkins.dev` from outside: Java (TCP 25565), Bedrock (a RakNet ping on
UDP 19132) and Bedrock NetherNet (`GET /v1/join` on TCP 19132), covering DNS,
the VM, the port forwards, and Velocity/Geyser. NetherNet gameplay on UDP
19133 has no check. The in-cluster Gatus checks the servers directly on
VLAN 50.

## Rebuilding the VM

`app/relay-launcher.yaml` is a CronJob (suspended) that launches the VM
every 10 minutes until Oracle has capacity, trying each AD in turn. It finds
its VM by display name (`NAME=minecraft-relay`), so renaming the VM in the
console makes it launch another. The cloud-init it passes sets up HAProxy and
the Bedrock relay; `launch.sh` fills the home WAN IP in from the secret. To rebuild:

1. Terminate `minecraft-relay` (keep the reserved IP).
2. Unsuspend the CronJob. The first run launches the VM with an ephemeral IP
   and sends a Pushover notification once it is RUNNING.
3. On the VM's primary private IP, set the public IP to none, then attach
   the `minecraft-relay` reserved IP. DNS and the UniFi source rule need no
   change.
4. Suspend the CronJob again.

## Secrets

`oci-api-secret` (Bitwarden Secrets Manager via ExternalSecrets) holds the
Oracle API key and the `minecraft-relay` compartment the VM, its network and
the reserved IP live in (`user`, `tenancy`, `compartment`, `fingerprint`,
`region`, `private_key_b64`) and `ssh_source_cidr`, the home WAN IP as a /32.
`bedrock-relay-launcher-secret` combines it with the shared `pushover` item;
the OpenTofu runner reads it as `oracle-relay-secret`.
