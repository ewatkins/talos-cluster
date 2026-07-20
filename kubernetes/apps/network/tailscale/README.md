# tailscale

In-cluster Tailscale, deployed via the official **tailscale-operator** Helm
chart. Replaces the standalone Tailscale VM: a cluster-native subnet router +
exit node ([`connector/connector.yaml`](connector/connector.yaml)) advertises
the home subnets onto the tailnet.

## Layout

- `app/` — the operator (`HelmRelease`), its OAuth `ExternalSecret`, and a
  dedicated **privileged** `tailscale` namespace (the subnet-router / exit-node
  proxy pods need `NET_ADMIN` + `/dev/net/tun`, which Talos's default
  `baseline` PodSecurity blocks).
- `connector/` — the cluster-scoped `Connector` (applied after the operator's
  CRDs exist, via `dependsOn`).

## Advertised routes

Defined in [`connector/connector.yaml`](connector/connector.yaml):

| Route          | Purpose                              |
| -------------- | ------------------------------------ |
| `10.35.0.0/16` | infra / hypervisor + NAS network     |
| `10.40.0.0/16` | cluster / services network           |
| `10.0.0.1/32`  | UniFi controller                     |

Exit-node duty is enabled (`exitNode: true`).

## Manual prerequisites (one-time)

1. **OAuth client** — in the Tailscale admin console
   (Settings → OAuth clients), create a client with the **Devices → Core**
   *write* scope, and tag it (e.g. `tag:k8s-operator`). Store it in Bitwarden
   Secrets Manager as an item named **`operator-oauth`** with fields:
   - `client_id`
   - `client_secret`
2. **Approve routes / exit node** — after the `Connector` registers, approve
   the advertised subnet routes and exit node under the device's settings in the
   admin console. To skip manual approval, add `autoApprovers` for the operator
   tag in your tailnet ACL policy.
3. Once verified, **decommission the standalone Tailscale VM**.
