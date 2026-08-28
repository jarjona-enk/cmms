# REQUIREMENTS.md — what the pipeline and the infrastructure need from you

Two environments, both in the shared `New-Implementations` resource group of
the `Enterprise` subscription (`d14f7b8e-d71d-4106-ab93-990c96df467c`):

| | test | prod |
|---|---|---|
| Web app | `cmms-test` | `cmms-prod` |
| Image | `enerkem.azurecr.io/cmms:test` | `enerkem.azurecr.io/cmms:prod` |
| Database | `atlastest` | `atlasprod` |
| Triggered by | `test/1.6.0-enerkem.1` | `release/1.6.0-enerkem.1` |
| Approval | none — deploys straight through | gate on the `cmms-prod` environment |

## Where configuration lives

Three places, deliberately, each for a reason:

| What | Where | Why there |
|---|---|---|
| Application settings | `infra/envs/<env>/main.tf` | OpenTofu owns them, so config is reviewable code and the web app cannot drift |
| Secrets | Azure Key Vault, seeded by hand | Tofu never reads them, so nothing sensitive reaches the state file or the pipeline |
| Public URL, SSO flags, subnet ids | Azure DevOps variable group | needed at *image build* time, before any infrastructure is applied |

The pipeline no longer writes application settings. If you change a setting in
the portal, the next `tofu apply` will change it back — edit `main.tf` instead.

---

## 1. Variable group `atlas-cmms-build`

Create it under **Pipelines → Library** and link it to the pipeline. Six
variables, none of them secret.

⚠️ Azure DevOps leaves an undefined `$(FOO)` as the literal string `$(FOO)`, so
a missing variable does not fail the run — it silently feeds garbage into a
build argument. Create all six.

| Variable | Example | What to put in it |
|---|---|---|
| `PUBLIC_URL_TEST` | `https://cmms-test.azurewebsites.net` | Public base URL of test, **no trailing slash** |
| `PUBLIC_URL_PROD` | `https://cmms.enerkem.com` | Public base URL of production, **no trailing slash** |
| `ENABLE_SSO` | `true` | Shows the "Continue with SSO" button in the built bundle |
| `OAUTH2_PROVIDER` | `microsoft` | `microsoft` for Entra, `google` for Google |
| `VNET_SUBNET_ID_TEST` | `/subscriptions/.../subnets/...` | Full resource id of the test integration subnet (see §4) |
| `VNET_SUBNET_ID_PROD` | `/subscriptions/.../subnets/...` | Same, for production |

### Why the URLs have to live here

Create React App compiles `REACT_APP_API_URL` **into the JavaScript bundle** at
image build time, which happens long before OpenTofu runs. So the URL cannot
come from the Tofu config — the pipeline passes it as a Docker build argument,
then hands the same value to Tofu as `TF_VAR_public_url` so both agree.

The consequence: **each image is specific to one environment.** `cmms:test` can
never be promoted to production; a release tag rebuilds from source.

---

## 2. Key Vault secrets

OpenTofu creates a vault per environment and grants the web app's managed
identity `Key Vault Secrets User`, but it never reads or writes the values. You
seed them once.

| Vault | Environment |
|---|---|
| `enkm-cmms-test` | test |
| `enkm-cmms-prod` | prod |

| Secret | What to put in it |
|---|---|
| `db-password` | Password for the `atlas` database user |
| `jwt-secret-key` | Session-token signing key. `openssl rand -base64 48`. Different per environment; rotating it logs everyone out |
| `oauth2-client-secret` | Client secret from the Entra app registration. **These expire** — record the date, because SSO fails silently when it lapses |
| `smtp-password` | Password or app-password for the SMTP account. Blank is fine while mail is off |

```bash
V=enkm-cmms-test
az keyvault secret set --vault-name $V --name db-password          --value '...'
az keyvault secret set --vault-name $V --name jwt-secret-key       --value "$(openssl rand -base64 48)"
az keyvault secret set --vault-name $V --name oauth2-client-secret --value '...'
az keyvault secret set --vault-name $V --name smtp-password        --value ''
```

**Set all four even when a value is unused** — blank, not absent. The app
settings reference them by name, and an unresolvable reference stops the
container from starting. Do this **after the first `tofu apply`** (the vault has
to exist) and **before the first deploy**.

The vaults use RBAC, so your account needs **Key Vault Secrets Officer** on them
to run those commands. Because the references are unversioned, rotating a secret
takes effect on the next restart — no redeploy.

---

## 3. Settings you edit in code

Everything else lives in `infra/envs/test/main.tf` and
`infra/envs/prod/main.tf`. The ones you are most likely to touch:

| Setting | Current | Notes |
|---|---|---|
| `oauth2_client_id` | **`REPLACE-WITH-ENTRA-APP-CLIENT-ID`** | must be filled in before the first apply |
| `oauth2_tenant_id` | `cddc5ffd-…` | the Enerkem directory. Required for a single-tenant registration, which rejects `/common` with `AADSTS50194` |
| `mail_recipients` | `cmms-admins@enerkem.com` | required even when mail is off — `application.yml` gives it no default |
| `enable_email_notifications` | `false` | turn on once SMTP is verified end to end |
| `invitation_via_email` | `false` | requires working mail; enabling it with broken SMTP locks new users out |
| `plan_sku` | `B2` test, `P1v3` prod | the JVM plus a cold-start Liquibase run needs the headroom |
| `db_fqdn` / `db_name` / `db_user` | `db-cancen-it-poet-test…` | see the open question in §4 |

Defaults for the rest — storage, SMTP host and port, CORS — are in
`infra/modules/cmms/variables.tf`.

---

## 4. Prerequisites

Nothing deploys until these exist.

### Databases — yours

On the flexible server, owned by the `atlas` role with DDL rights (Liquibase
runs the whole changelog on every boot, and JPA validates the schema after):

```sql
CREATE DATABASE atlastest OWNER atlas;
CREATE DATABASE atlasprod OWNER atlas;
```

### VNet integration subnets — network team

One per environment: a **/28 or larger, delegated to
`Microsoft.Web/serverFarms`**, in a VNet with a route to the database. Pass the
resource ids in as `VNET_SUBNET_ID_TEST` / `VNET_SUBNET_ID_PROD`.

These are not created by our config on purpose — they live in the shared network
resource group, outside the blast radius we agreed on.

> ⚠️ **Open question, blocking.** `db-cancen-it-poet-test` has
> `publicNetworkAccess: Disabled` and is injected into
> `New-Implementations-vnet` (canadacentral), whose only subnet is a /24
> already delegated to PostgreSQL — no room for an App Service subnet, and the
> wrong region for a canadaeast web app, since regional VNet integration needs
> the VNet in the same region as the plan.
>
> Meanwhile every existing App Service integration subnet is a /28 in
> `VNET-CanEast-Tier1` (canadaeast), and the *other* server,
> `db-caneast-django-pmo-test`, is already reachable from there through a
> private endpoint.
>
> So one of: use `db-caneast-django-pmo-test` instead (easiest by far), peer
> the two VNets and link the private DNS zone, or move the app to canadacentral
> and widen that VNet. See DEVELOPMENT-STATUS.md §11.

### Entra app registration — IT

- Redirect URI `<public_url>/oauth2/callback/microsoft`, **one per environment**
- Delegated Microsoft Graph `openid`, `email`, `profile`
- A client secret, which goes into each vault as `oauth2-client-secret`

### Azure DevOps environment — you

Create an environment named **`cmms-prod`** (Pipelines → Environments) and add
an approval check on it. That is what gates production; the pipeline's `Prod`
stage is a deployment job bound to it. Without the check the stage still runs,
just without asking.

`cmms-test` needs no environment — it deploys straight through, as agreed.

### Service principal permissions

The `azureSubscriptionServiceConnection` principal needs, on
`New-Implementations`:

| Role | Why |
|---|---|
| **Contributor** | create and manage the resources |
| **User Access Administrator** | the four role assignments per environment. Contributor alone cannot grant roles — **this is the one most likely to need a request** |
| **Storage Blob Data Contributor** on `enkmtfstate001` | the state backend uses `use_azuread_auth`, so it reads and writes state as the SPN rather than with an account key |

### OpenTofu state — once

```bash
cd infra/bootstrap && tofu init && tofu apply
```

Creates `enkmtfstate001` and its `tfstate` container. See `infra/README.md` for
migrating bootstrap's own state into it afterwards.

---

## 5. Releasing

```bash
git tag test/1.6.0-enerkem.1     && git push origin test/1.6.0-enerkem.1      # -> cmms-test
git tag release/1.6.0-enerkem.1  && git push origin release/1.6.0-enerkem.1   # -> cmms-prod
```

Tags must carry the upstream release number they are built on. The first
pipeline step validates this against `UPSTREAM_VERSION` and fails otherwise:

| Tag | Result while `UPSTREAM_VERSION` is `1.6.0` |
|---|---|
| `test/1.6.0-enerkem.1` | deploys to test |
| `release/1.6.0-enerkem.1` | deploys to prod, after approval |
| `release/1.7.0-enerkem.1` | **rejected** — upstream v1.7.0 is not merged |
| `release/1.6.0` | **rejected** — no `-enerkem.<n>` counter |
| `release/v1.6.0-enerkem.1` | **rejected** — no `v` prefix |

The normal flow is to ship the same version to test first, then re-tag it for
release once it looks good. Both tags rebuild from source, because the public
URL is baked into the bundle.

### What a run does

**Build** — one `docker build` from the repository root. `api/Dockerfile` zips
the whole repo for AGPLv3 §13, then builds the entire Maven reactor inside
`maven:3.9.3-eclipse-temurin-17` (Node via `frontend-maven-plugin`, `npm ci`,
CRA production build, SPA copied into `classpath:/static`, fat jar packaged) and
lands on `amazoncorretto:17-alpine`. **Java 17 throughout** — newer JDKs break
Lombok here, so the version is pinned in the Dockerfile, not a variable.

**Verify** — starts Postgres and the image on the agent with throwaway
credentials, waits for `/health-check`, then asserts the container really serves
the frontend: the SPA shell at `/`, `asset-manifest.json`, the main JS bundle it
names, a deep link forwarding through `SpaForwardController`, and a non-empty
`/source-code/download`. A jar that boots with an empty `classpath:/static`
passes a health check and fails every one of these.

**Publish** — pushes `cmms:<env>` and `cmms:<version>` to `enerkem.azurecr.io`,
only after the smoke test passes.

**Deploy** — `tofu plan` then `tofu apply` for that environment, then
`az webapp restart` so App Service re-pulls the moving tag, then a poll of the
public URL for the SPA shell for up to 10 minutes. The restart returns
immediately and a container that fails to start leaves the previous one serving,
which looks like success — hence the poll.

Expect **15–25 minutes**, dominated by `npm ci` and the CRA build.

### Rollback

Every release also pushes an immutable `cmms:<version>` tag:

```bash
az webapp config container set --name cmms-prod --resource-group New-Implementations \
  --docker-custom-image-name enerkem.azurecr.io/cmms:1.6.0-enerkem.1
```

That drifts from the Tofu config, which pins `cmms:prod` — so it is a stopgap.
Follow it by re-tagging and re-releasing the good version properly.

---

## 6. First-run order

1. `infra/bootstrap` — create the state account
2. Create the two databases
3. Get the two subnets created, resolve the region question in §4 first
4. Entra app registrations; put the client id into both `main.tf` files
5. Create the `atlas-cmms-build` variable group (all six variables)
6. Create the `cmms-prod` environment with an approval check
7. Grant the service principal its three roles
8. Tag `test/…` — the run will apply infrastructure and then fail the SPA poll,
   because the vault is still empty
9. Seed the four secrets in `enkm-cmms-test`
10. Re-run the deploy stage, or push the next `test/…` tag
11. Once test is good, repeat 8–10 for `release/…`

Steps 8–10 look awkward but are unavoidable: the vault must exist before you can
put secrets in it, and the app cannot start until they are there.
