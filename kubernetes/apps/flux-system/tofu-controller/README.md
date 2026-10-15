# [Tofu Controller](https://github.com/flux-iac/tofu-controller)

Flux controller that reconciles `Terraform` objects by running OpenTofu in
short-lived runner pods. It is how the Calagopus Wings VMs on Proxmox are
managed from Git: see
[`default/calagopus/wings`](../../default/calagopus/README.md) and
[`terraform/wings`](../../../../terraform/wings/README.md).

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Chart | `oci://ghcr.io/flux-iac/charts/tofu-controller` `0.16.5` | CRDs from the chart, `CreateReplace` on install and upgrade |
| Runner image | `ghcr.io/flux-iac/tf-runner` (chart default) | Bundles OpenTofu |
| Cross-namespace refs | Allowed | `Terraform` objects live in their own namespaces and read the `talos-cluster` GitRepository in `flux-system` |
| Runner service account | Per `Terraform` object | The chart's `tf-runner` account (flux-system only) is bound to read/write on **every Secret in the cluster**. Give each `Terraform` object its own namespace and a namespace-scoped account via `serviceAccountName`, as `calagopus-wings` does |
| AWS package | Off | |
| Metrics | ServiceMonitor | |

## Working with a `Terraform` object

State lives in a Secret beside the object (`tfstate-default-<name>`), so
the object's namespace should not be pruned.

`calagopus-wings` uses `approvePlan: auto`: merging applies. The review step
is the **branch planner**, which polls open PRs every minute and posts a
plan-only run for each PR branch that changes the object's `path`
(`branchPlanner.enablePathScope`) as a comment (`!replan` refreshes it).
Each new plan comment deletes the older ones on that PR
(`.github/workflows/tofu-plan-comments.yaml`), so the one left is current.
A branch is planned as it stands, so rebase a stale branch before trusting
its plan. It plans against the object's real state, runs with the object's own runner
account, and can only plan. Branches are fetched from this repo by name,
so PRs from forks are never planned with the cluster's credentials. It signs
in as the repo's bot GitHub App (`branch-planner-token`, from the
`renovate-operator` Bitwarden item and `cluster-secrets`); to plan another
`Terraform` object, add it to `resources` in `app/branch-planner.yaml`.

For an object left on manual approval (`approvePlan: ""`), approve **in the
cluster**, not in Git: the controller sees an approval commit's new revision
before Flux applies it, and replaces the pending plan.

```sh
kubectl -n <ns> get terraform <name>                   # READY message shows the plan ID
kubectl -n <ns> patch terraform <name> --type merge -p '{"spec":{"approvePlan":"<plan ID>"}}'
```
