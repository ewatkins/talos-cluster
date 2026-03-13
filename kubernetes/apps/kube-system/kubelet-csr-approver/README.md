# [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver)

kubelet-csr-approver automatically approves `CertificateSigningRequest` resources submitted by kubelets, removing the need for manual certificate approval when nodes join or rotate their certificates.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Approved nodes | `superior`, `huron`, `michigan`, `erie`, `ontario`, `tahoe` | CSRs from other hostnames are rejected |
| DNS bypass | `bypassDnsResolution: true` | Required for Talos nodes whose hostnames do not resolve via cluster DNS |

## Links

- [GitHub Repository](https://github.com/postfinance/kubelet-csr-approver)
- [Helm Chart](https://github.com/postfinance/kubelet-csr-approver/tree/main/deploy/charts/kubelet-csr-approver)
