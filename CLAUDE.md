# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A GitOps-managed Kubernetes home lab running on **Talos Linux** (5 nodes named after the Great Lakes: superior, huron, michigan, erie, ontario) on a Proxmox hypervisor. Flux CD watches `kubernetes/apps/` and reconciles cluster state from Git. Renovate Bot auto-creates PRs for dependency updates.

## Common Commands

All automation uses [Go Task](https://taskfile.dev). Run `task` with no args to list all available tasks.

```bash
task                          # List all tasks
task configure                # Full bootstrap: template → encrypt → validate
task flux:reconcile           # Force Flux to sync Git → cluster
task flux:apply               # Apply a specific kustomization
task kubernetes:kubeconform   # Validate all manifests against schemas
task kubernetes:resources     # Gather cluster diagnostics
task talos:bootstrap          # Initialize a new cluster (etcd → kubeconfig → apps)
task talos:upgrade node=NODE  # Upgrade a single Talos node (e.g., node=superior)
task talos:upgrade-k8s        # Upgrade Kubernetes version
task sops:encrypt             # Encrypt all .sops.yaml files
task workstation:deps         # Install required CLI tools locally
```

**Environment requirements:** `KUBECONFIG=./kubeconfig` and `SOPS_AGE_KEY_FILE=./age.key` are set automatically by Task. A Python virtualenv at `.venv/` is required for templating (`task workstation:venv`).

## Repository Structure

```
kubernetes/
├── apps/          # All application deployments (15 namespaces/categories)
├── bootstrap/     # One-time cluster bootstrapping resources
├── components/    # Reusable Kustomize components shared across apps
└── flux/          # Flux system config, variables, and top-level Kustomizations
talos/
├── talconfig.yaml         # Cluster definition (talhelper input)
├── clusterconfig/         # Generated Talos node configs (do not hand-edit)
└── talsecret.sops.yaml    # Encrypted Talos secrets
.taskfiles/        # Task module definitions (one per concern)
.renovate/         # Renovate bot configuration modules
bootstrap/         # Makejinja templates for generating kubernetes/ and talos/ configs
```

## Key Architectural Patterns

### GitOps Flow
Flux watches `kubernetes/apps/` recursively (every 30 min). Each app has a `ks.yaml` (Flux `Kustomization` resource) that points to its directory. Secrets are decrypted by Flux using the `sops-age` Kubernetes secret at reconcile time.

### App Structure
Every application follows this pattern:
```
kubernetes/apps/<namespace>/<app>/
├── ks.yaml           # Flux Kustomization(s) with dependsOn, postBuild substitutions
├── kustomization.yaml # Kustomize entrypoint
├── helmrelease.yaml  # HelmRelease with chart source and values
└── ...               # Additional resources (certificates, ingress, etc.)
```

### Secret Management
- **SOPS + Age** for secrets in Git: only `data`/`stringData` fields are encrypted (metadata stays readable)
- **ExternalSecrets Operator + Bitwarden** for runtime secrets synced into the cluster
- Age public key: `age16ve7n3m9ucqtxgfv220gdf7wlgp8vhurx5vspw365g797vwy5pds56p93y`
- Never commit `age.key` or `kubeconfig` — both are git-ignored
- SOPS config is in `.sops.yaml`; run `task sops:encrypt` after editing any `.sops.yaml` file

### Variable Substitution
Flux applies post-build variable substitution using two sources:
- `cluster-settings` ConfigMap (`kubernetes/flux/vars/cluster-settings.yaml`) — non-secret values like node IPs and service IPs
- `cluster-secrets` SOPS-encrypted Secret — sensitive values like domain names and credentials

Use `${VARIABLE_NAME}` syntax in manifests; variables are defined in those two files.

### Networking
- CNI: **Cilium** (eBPF)
- Load balancer: **kube-vip** (VIP: `10.40.1.100`)
- Ingress: **NGINX** (internal + external)
- DNS: **k8s-gateway** (`10.40.0.20`) + CoreDNS for in-cluster

### Storage
- **OpenEBS** (default local storage)
- **Minio** (S3-compatible object storage for Loki, Thanos, etc.)

### Node Upgrades
- **tuppr** manages Talos and Kubernetes upgrades (replaced system-upgrade-controller)
- Upgrade specs live in `kubernetes/apps/system-upgrade/tuppr/upgrades/`

## Talos Cluster Details

- Cluster name: `great-lakes`
- Talos version: v1.12.4 | Kubernetes: v1.35.1
- Node IPs: superior=10.40.1.1, huron=10.40.1.2, michigan=10.40.1.3, erie=10.40.1.4, ontario=10.40.1.5
- Pod CIDR: `10.69.0.0/16` | Service CIDR: `10.96.0.0/16`
- Generated node configs live in `talos/clusterconfig/` — regenerate with `talhelper genconfig` after editing `talconfig.yaml`

## Validation

Before committing changes to manifests, run:
```bash
task kubernetes:kubeconform   # Schema validation
```

CI runs `flux-local` validation on PRs (`.github/workflows/flux-local.yaml`).
