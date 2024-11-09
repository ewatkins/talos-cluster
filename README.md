<dl>
<dd>
<div>
<img src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo_with_border.svg" align="left" width="100px" height="100px"/>

#### &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;My Talos Cluster / HomeLab

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_Built on Talos and Proxmox_

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_Managed with Flux, Renovate, and GitHub Actions_ 🤖

</div>
</dd>
</dl>

---

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dtalos_version&style=for-the-badge&logo=talos&logoColor=FF7300&color=222222&label=%20)](https://www.talos.dev/)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=326CE5&label=%20)](https://kubernetes.io/)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/ewatkins/talos-cluster/renovate.yaml?branch=main&label=&logo=renovate&style=for-the-badge&color=blue)](https://github.com/ewatkins/talos-cluster/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Ffbfbdbca-dcc6-4afb-b805-aa951be107ab.shields&label=Home%20Internet&style=for-the-badge&logo=tmobile&logoColor=white&labelColor=222222)](https://status.ewatkins.dev)&nbsp;&nbsp;
[![Status-Page](https://img.shields.io/uptimerobot/status/m797091225-baba12b223916efaf9441add?color=brightgreen&label=Status%20Page&style=for-the-badge&logo=statuspage&logoColor=white&labelColor=222222)](https://status.ewatkins.dev)&nbsp;&nbsp;
[![Alert Manager](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Fac7b0558-1361-42ec-9f31-06d18a40aca8.shields&style=for-the-badge&logo=prometheus&logoColor=white&labelColor=222222)](https://status.ewatkins.dev)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&label=Age&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&label=Uptime&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&label=Nodes&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&label=Pods&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&label=CPU&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ewatkins.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&label=Memory&style=for-the-badge&labelColor=222222)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;

</div>

---

### 📖 Overview

This is my mono-repository for my home Kubernetes cluster following GitOps principles and Infrastructure as Code. The purpose of this cluster is mostly a learning exercise, but with the ultimate benefit of having something solid to work with in my home environment.

---

### ⚓ Kubernetes

My Kubernetes Cluster is deployed using [Talos](https://www.talos.dev/) Linux. It currently is running as five virtual machines located on a singular Proxmox node, but in the future I will be separating into individual Proxmox nodes. I am primarily using OpenEBS for local storage, and Minio for object storage. The Talos VMs are backed up to an external drive regularly.

#### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [cert-manager](https://github.com/cert-manager/cert-manager): Creates SSL certificates for services in my cluster.
- [cilium](https://github.com/cilium/cilium): Internal Kubernetes container networking interface.
- [cloudflared](https://github.com/cloudflare/cloudflared): Enables Cloudflare secure access to certain ingresses.
- [grafana](https://grafana.com/): Visualization into my cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically syncs ingress DNS records to a DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using an external provider (Bitwarden).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Kubernetes ingress controller using NGINX as a reverse proxy and load balancer.
- [prometheus](https://prometheus.io/): Cluster monitoring and metrics.
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes and Terraform which are commited to Git.
- [spegel](https://github.com/spegel-org/spegel): Stateless cluster local OCI registry mirror.

#### _TODO_: Currently on hold

- [rook-ceph](https://github.com/rook/rook): Distributed storage for peristent storage.
- [volsync](https://github.com/backube/volsync): Backup and recovery of persistent volume claims.

#### GitOps

[Flux](https://fluxcd.io) watches my cluster in the Kubernetes folder and makes the changes to my cluster based on the state within my Git repository.

The way Flux works for my cluster is by recursively searching the `kubernetes/apps` folder until it finds the top most `kustomization.yaml` per directory and then apply all resources listed within. The `kustomization.yaml` file will contain a namespace and one or more `ks.yaml` Flux kustomizations. Within those Flux kustomzations will be `HelmReleases` which dictate the resources that are applied for the specific application.

[Renovate](https://github.com/renovatebot/renovate) watches everything within the repository looking for updates. Once an update is found it creates a Pull Request in Github, allowing me to review changes before merging them. Once these changes are merged, Flux picks them up and applies the changes.

#### Directories

This Git repostories contains the following directories under [Kubernetes](https://github.com/ewatkins/talos-cluster/tree/main/kubernetes)

```sh
📁 kubernetes
├── 📁 apps           # applications
├── 📁 bootstrap      # bootstrap procedures
├── 📁 flux           # core flux configuration
└── 📁 templates      # re-useable components
```

---

### 🌩️ Cloud Dependencies

While I try to self-host almost everything myself, there are a couple of things that I currently maintain outside of the cluster for ease. Some of these are critical services that are just plain required, while others are luxuries that won't bankrupt me.

| Service                                     | Use                                                                                                         |   Cost |
| :------------------------------------------ | :---------------------------------------------------------------------------------------------------------- | -----: |
| [Bitwarden](https://bitwarden.com/)         | External Password Manager, and Secrets Manager with [External Secrets](https://external-secrets.io/)        | $10/yr |
| [Cloudflare](https://cloudflare.com/)       | Domain Registration and Cloudflare Tunnels                                                                  | $10/yr |
| [GitHub](https://github.com/)               | Hosting this repository and continuous integration/deployments                                              |   Free |
| [Pushover](https://pushover.net/)           | Kubernetes Alerts and application notifications                                                             |     $5 |
| [UptimeRobot](https://uptimerobot.com/)     | Monitoring external facing applications                                                                     |   Free |
| [Healthchecks.io](https://healthchecks.io/) | Heartbeat Monitoring for AlertManager and Internet                                                          |   Free |
|                                             | <div align="right">Total:</div>                                                                             | $20/yr |

---

### 🌐 Public DNS

I am currently using [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to create public DNS records in Cloudflare for externally facing applications and endpoints. I use the external ingress name and external ingress annotations to determine if an application is internal or external.

### 🏠 Home DNS

For my Home DNS I am using Pi-Hole (for now). Along with Pi-Hole I am utilizing the CoreDNS plugin, [k8s_gateway](https://github.com/ori-edge/k8s_gateway) to be able to automatically resolve internal dns using split DNS and dnsmasq.

---

### 🤝 Gratitude and Thank You!

Massive shoutout to the home-operations group, it has been fun lurking.
