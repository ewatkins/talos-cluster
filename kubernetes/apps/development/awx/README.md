# [AWX](https://github.com/ansible/awx)

AWX is the upstream project behind Ansible Automation Platform: a web UI, REST API, and task engine for running Ansible playbooks. It is deployed here as two Flux Kustomizations — `awx-operator` installs the operator and its CRDs, `awx` applies the `AWX` custom resource the operator reconciles into the actual deployment.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://awx.ewatkins.dev` | Internal gateway only; no external route |
| Operator | `awx-operator` Helm chart 3.2.1 (appVersion 2.19.1) | From `https://ansible-community.github.io/awx-operator-helm/` |
| Watch scope | `development` namespace only | The chart grants the controller a namespaced Role, so the `AWX` CR must live alongside the operator |
| Database | `awx` user/database on the PG17 Crunchy cluster | Declared in `kubernetes/apps/database/crunchy-postgres-operator/cluster/pg17/cluster.yaml`; picks up pgBackRest backups to Garage and R2 |
| Admin user | `admin`, password from `awx-secret` | Bitwarden item; changing it in Bitwarden does not change an already-created account, AWX only reads it on first boot |
| Ingress | Gateway API `HTTPRoute` | `ingress_type: none` on the CR — the operator manages no Ingress of its own |

## Database

`postgres_configuration_secret` points at `awx-postgres-configuration`, an ExternalSecret pulled from the `crunchy-postgres` ClusterSecretStore (`crunchy-postgres-17-pguser-awx`). It sets `type: unmanaged`, which is what stops the operator from provisioning its own single-replica Postgres StatefulSet.

It connects to `crunchy-postgres-17-primary` directly rather than through pgBouncer. AWX's task dispatcher uses PostgreSQL `LISTEN`/`NOTIFY`, which does not survive a connection pooler; upstream does not support running AWX behind pgBouncer.

AWX's migrations create the `pg_trgm` and `citext` extensions. Both are trusted extensions in PostgreSQL 13+, so the database owner can create them without superuser — no extra grant is needed beyond what `crunchy-userinit-controller` already does for the cluster.

## Required Bitwarden item

One item, `awx-secret`, must exist in Bitwarden Secrets Manager before the `awx` Kustomization will reconcile:

| Field | Notes |
| --- | --- |
| `secret_key` | Django `SECRET_KEY`. AWX encrypts every stored credential with it — rotating it makes all of them unrecoverable, so it must stay stable for the life of the install |
| `password` | Initial password for the `admin` account. Only read on first boot; changing it later in Bitwarden does not change an existing account |

Both `secret_key_secret` and `admin_password_secret` on the CR point at the single `awx-secret` Secret. The operator looks each one up by name and reads exactly one key (`secret_key` / `password`), and mounts `SECRET_KEY` through an explicit `items` projection, so the unused key in each case is never seen by AWX.

The database credentials stay in their own Secret — `postgres_configuration_secret` also expects a `password` key, which would collide, and they come from a different secret store.

## Notes

- First reconcile is slow. The operator runs the full AWX migration set inside an Ansible run before the web pod becomes ready, which is why the `awx` Kustomization has a 20m timeout.
- `create_preload_data: false` skips the demo inventory, project, and job template the operator otherwise seeds.
- No `projects_persistence`: project directories are `emptyDir` and re-cloned per job. Set it (with an RWX class such as `nfs-fast`) if manual projects are ever needed.
- The operator uses Helm's `crds/` directory, so `helm upgrade` does not update the AWX CRDs. `crds: CreateReplace` on the HelmRelease is what keeps them in sync across chart bumps.
