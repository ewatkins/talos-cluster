# Alexandrie

Self-hosted wiki / knowledge base with an extended Markdown editor
([upstream](https://github.com/Smaug6739/Alexandrie)). Running as a trial alongside
[Outline](../outline/README.md); if it wins, the hostname moves to `notes.ewatkins.dev`.

| | |
| --- | --- |
| URL | `https://wiki.ewatkins.dev` |
| CDN | `https://s3-notes.ewatkins.dev` |
| Database | MariaDB Galera, database `alexandrie` |
| Object storage | RustFS, in-pod, 20Gi on `nfs-fast` |

Two containers in one pod — a Go/Gin backend on `:8201` serving everything under `/api`, and
a Nuxt/Nitro frontend on `:8200` — plus a separate RustFS controller.

## It is MySQL-only

Not a configuration choice. `backend/app/app.go` imports only `go-sql-driver/mysql`, the
migration runner hardcodes `mysql.WithInstance(...)`, and the schema is MySQL dialect
throughout: backtick quoting, `ENGINE=InnoDB`, `JSON_OBJECT()`, and `FULLTEXT` indexes
queried with `MATCH ... AGAINST (? IN NATURAL LANGUAGE MODE)`. `lib/pq` appears in `go.sum`
as an unused transitive of golang-migrate and is not in `go.mod`.

So it uses the [MariaDB Galera cluster](../../database/mariadb/README.md) rather than Crunchy
Postgres, with the usual `Database` / `User` / `Grant` trio. `DATABASE_HOST` points at
`mariadb-primary` and not `maxscale`: the app runs its own DDL migrations on boot, and
routing those through the load balancer invites multi-master conflicts.

Two GeoIP tables in the schema (`city_ipv4_complete`, `city_ipv6_complete`) have no primary
key, which Galera does not support for `DELETE`. Harmless here — the code only ever `SELECT`s
from them.

> **The `User` CR does not retry on a missing secret.** If the Bitwarden item does not exist
> when mariadb-operator first reconciles, the User lands in `Error creating alexandrie: error
> reading user password secret` and stays there. Nudge it once the secret is present:
> `kubectl annotate user.k8s.mariadb.com -n database alexandrie nudge="$(date +%s)" --overwrite`

## Why object storage is self-hosted

The backend calls `SetBucketPolicy` on every boot and `os.Exit(1)`s if it fails:

```go
err = minioClient.SetBucketPolicy(ctx, bucketName, policy)
if err != nil { logger.Error(...); os.Exit(1) }
```

That rules out both of the obvious existing options. **Garage** does not implement
`PutBucketPolicy` at all. **iDrive e2** returns `Access Denied` for it on a bucket-scoped
access key, which is the only kind it issues — confirmed against a live bucket, which the
same key was able to *create* but not set a policy on. Setting the policy by hand in the e2
console does not help, because the call still has to succeed on each boot.

RustFS is what upstream's `docker-compose.yml` ships, so the call is known to work against
it. It creates `notes` (public-read) and `notes-backups` (private, 24h lifecycle) itself on
first boot; the `-backups` suffix is hardcoded in `utils.GetBackupBucketName()` and is not
configurable.

> **RustFS is on `1.0.0-rc.4`**, a release candidate. MinIO is the swap if it misbehaves.

> **The backend races RustFS on a cold start.** It exits on `connection refused` if RustFS is
> not listening yet, then succeeds on the restart. Left to CrashLoopBackOff rather than
> papered over with a wait-for init container.

### The CDN needs its own hostname

`s3-notes.ewatkins.dev` is deliberately *not* a path on the app's hostname. The service
worker registers its asset cache as a catch-all on the CDN origin:

```ts
// frontend/app/sw.ts
registerRoute(({ url }) => url.origin === __BASE_CDN__, new NetworkFirst({...}))
```

Share an origin with the frontend and that puts the entire application behind a network-first
cache strategy.

Objects are public-read by the bucket policy the backend sets, so the route is
unauthenticated by design — it is internal-gateway only. The public/signing client hardcodes
`BucketLookupPath`, so asset URLs are path-style: `<cdn>/<bucket>/<user_id>/<file>`. That
means `NUXT_PUBLIC_CDN_ENDPOINT` **is** the bucket name and has to move with `MINIO_BUCKET`.

Health of the whole chain, without needing an object to exist:

```bash
curl -sI https://s3-notes.ewatkins.dev/notes/            # 403 — listing denied
curl -sI https://s3-notes.ewatkins.dev/notes/nonexistent # 404 — anonymous GetObject allowed
```

A `403` on the second means the public-read policy did not apply.

## OIDC

Providers come from **indexed environment variables**, not a config file or an admin UI —
`OIDC_1_*` through `OIDC_10_*`, in `backend/oidc/config.go`. A slot is skipped entirely if
its `CONFIG_URL` is empty. Endpoints and scopes are negotiated from the discovery document,
so there is nothing else to declare.

| Variable | Value |
| --- | --- |
| `OIDC_1_PROVIDER_NAME` | `Keycloak` — the login button label |
| `OIDC_1_CLIENT_ID` | `alexandrie` |
| `OIDC_1_CONFIG_URL` | `https://keycloak.ewatkins.dev/realms/master/.well-known/openid-configuration` |
| `OIDC_1_CLIENT_SECRET` | Bitwarden `alexandrie-secret` → `oidc_client_secret` |

Keycloak client `alexandrie` in the `master` realm: client authentication **on**, standard
flow enabled, valid redirect URI `https://wiki.ewatkins.dev/login/oidc/callback`, web origin
`https://wiki.ewatkins.dev`. The frontend builds that URI as
`window.location.origin + '/login/oidc/callback'`, so it tracks the app hostname.

`PROVIDER_NAME` is lowercased into the API path, giving `/api/auth/oidc/keycloak/authorize`.

> **Discovery runs once, at startup, behind a `sync.Once`.** If Keycloak is unreachable when
> the backend boots, the provider is dropped with a logged error and does not reappear until
> the pod restarts. A provider with an empty client secret is rejected the same way — logged
> and skipped, never a failed boot.

Native login is **off** — Keycloak is the only way in. That takes two variables in two
containers, because the check exists in both:

| Variable | Container | Effect |
| --- | --- | --- |
| `CONFIG_DISABLE_NATIVE_LOGIN` | backend | `Login()` returns `403 native login is disabled` before it reads the body |
| `NUXT_PUBLIC_CONFIG_DISABLE_NATIVE_LOGIN` | frontend | Disables the username/password inputs and prints "login disabled" |

The backend one is the enforcement; the frontend one is cosmetic. Flip them together.

> **`CONFIG_HIDE_NATIVE_LOGIN` is broken in v8.14.0** and is deliberately not set.
> `nuxt.config.ts` declares `configHideNativeLogin`, but `LoginBase.vue` reads
> `config.public.configHideLoginForm` — a key that is not declared, and Nuxt only maps
> `NUXT_PUBLIC_*` onto declared keys. It is `undefined` however it is spelled, so the form
> fields stay on the page, greyed out.

`CONFIG_OIDC_PROVIDER_AUTO_REDIRECT` (frontend, value `keycloak`) would skip the page
entirely, bouncing straight to Keycloak on mount. Left off: with native login disabled there
would be no way back to a working login page if Keycloak were down.

Signup is still open (`CONFIG_DISABLE_SIGNUP: "false"`), so accounts can still be created
with a password — they just cannot log in with one afterwards. Existing accounts link a
provider from *Settings → Security*.

## Admin role

`ADMIN_ACCOUNTS` is the only source of the administrator role — a comma-separated list of
user snowflake IDs. Signup does not grant it to anyone, OIDC or native, first account
included (`createUserFromOIDC` hardcodes `Role: 1`).

It is authoritative in both directions: `LoadAppAdmins()` runs at every startup and demotes
any existing admin whose ID is absent, so removing someone here revokes their role on the
next pod restart.

```bash
kubectl exec -n database -it mariadb-0 -- \
  mariadb -u alexandrie -p alexandrie -e "SELECT id, username, role FROM users;"
```

## Usernames cannot be changed in-app

OIDC signup appends a six-digit suffix derived from the user's snowflake
(`GenerateUniqueUsername` → `<name>-<id % 1000000>`), unconditionally. The profile field is
`disabled` in the UI, and `UpdateUser` takes no username argument — it re-writes the stored
value on every save. Renaming means editing the row:

```bash
kubectl exec -n database -it mariadb-0 -- \
  mariadb -u alexandrie -p alexandrie \
  -e "UPDATE users SET username='ewatkins' WHERE id=748635670972596225;"
```

Safe: `username` carries a plain index, not a unique constraint, and OIDC accounts
authenticate on `user_oidc_providers.provider_user_id`. It is the login key for *native*
password auth, though, so it matters if a password is ever set on the account.

## Secrets

Bitwarden Secrets Manager, two items:

| Item | Fields |
| --- | --- |
| `alexandrie-db-secret` | `password` — MariaDB user; also read by the `User` CR in the `database` namespace |
| `alexandrie-secret` | `jwt_secret`, `s3_access_key_id`, `s3_secret_access_key`, `oidc_client_secret` |

The `s3_*` pair is a shared secret between the backend and RustFS — both containers mount the
same Kubernetes secret, under `MINIO_*` and `RUSTFS_*` names respectively, so the values match
by construction. The names are held over from the abandoned iDrive e2 attempt; the values now
mean nothing outside the cluster.

SMTP reuses the shared `smtp` item, for password-reset mail only.

> **Rotating `JWT_SECRET` invalidates every session and every outstanding password-reset
> link.** Both are signed with it.

> **Alexandrie forces implicit TLS on port 465** (`mail.WithSSL()`, no port setting). A
> relay that only speaks 587/STARTTLS will fail at send time — the app still boots, and
> nothing but password reset is affected.

## Trade-offs

- Wiki media lives on `nfs-fast`, so it is on the NAS rather than node-local — but
  Alexandrie's own backup bucket lands on the *same* volume, so those are not independent
  copies.
- `notes` as a bucket name overlaps conceptually with Outline, which serves
  `notes.ewatkins.dev` today and keeps its own `outline` bucket on Garage. No actual
  collision; worth remembering if Alexandrie wins the trial.
