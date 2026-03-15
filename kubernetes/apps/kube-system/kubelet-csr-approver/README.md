# [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver)

kubelet-csr-approver automatically approves `CertificateSigningRequest` resources submitted by kubelets, removing the need for manual `kubectl certificate approve` steps when nodes join the cluster or rotate their TLS credentials.

## Chart

| Field | Value |
| --- | --- |
| Chart | `postfinance/kubelet-csr-approver` |
| Version | `1.2.13` |
| Source | HelmRepository `postfinance` in `flux-system` |

## Configuration

| Setting | Value |
| --- | --- |
| `providerRegex` | `^(superior\|huron\|michigan\|erie\|ontario\|tahoe)$` |
| `bypassDnsResolution` | `true` |
| Metrics | enabled |
| ServiceMonitor | enabled |

The `providerRegex` restricts automatic approval to CSRs whose common name matches one of the six listed hostnames — the five Great Lakes cluster nodes plus `tahoe`. Any CSR from an unrecognised hostname is denied.

`bypassDnsResolution: true` is required because Talos node hostnames do not resolve through cluster DNS; the approver validates node identity via the node object instead.

## Links

- [GitHub Repository](https://github.com/postfinance/kubelet-csr-approver)
- [Helm Chart](https://github.com/postfinance/kubelet-csr-approver/tree/main/deploy/charts/kubelet-csr-approver)
