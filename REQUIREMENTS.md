# REQUIREMENTS.md — what the pipeline and the infrastructure need from you

Two environments, both in the shared `New-Implementations` resource group of
the `Enterprise` subscription (`d14f7b8e-d71d-4106-ab93-990c96df467c`):

| | test | prod |
|---|---|---|
| Web app | not created yet | **`cmms`** (site containers) |
| Image pulled | — | `enerkem.azurecr.io/cmms:latest` |
| Database | `atlastest` on `db-caneast-django-pmo-test` | `atlas` on `db-caneast-pmdms` |
| Triggered by | `test/1.6.0-enerkem.1` | `release/1.6.0-enerkem.1` |
| Approval | none — deploys straight through | gate on the `cmms-prod` environment |

⚠️ **There is only one web app today.** `cmms` was created by hand as a *site
containers* app whose main container pulls `enerkem.azurecr.io/cmms:latest`, on
the shared `ASP-dev-pmo-project-tracking-a972` plan (B3), with no VNet
integration and no application settings beyond
`WEBSITES_ENABLE_APP_SERVICE_STORAGE`. §7 lists what it still needs before a
container can boot on it.

Because production pulls `:latest` and every release moves `:latest`, a
`test/…` tag changes the image production will pull on its next restart. Until
a separate test app exists, treat `:latest` as production's tag.

## Where configuration lives

Three places, deliberately, each for a reason:

| What | Where | Why there |
|---|---|---|
| ~~Application settings~~ | ~~`infra/envs/<env>/main.tf`~~ | **OpenTofu is parked** (`infra/README.md`). Settings come from `.azure/env/prod.env` instead |
| Secrets | Azure Key Vault `enkm-cmms-<env>`, seeded by hand, referenced from app settings | nothing sensitive reaches the repo, the state file, the pipeline, or anyone reading the app config. Rotation needs no deploy (§2) |
| Deployment settings and non-secret app settings | `.azure/env/prod.env`, committed | reviewable in git; pushed onto the web app by the deploy task (§1) |

**OpenTofu is parked.** Production infrastructure was built by hand and is
ready; `infra/` has never been applied and must not be applied now (it would
build a second, parallel set of resources). See `infra/README.md`.

The pipeline is **production-only** and creates no infrastructure. One
`release/*` tag, one job: build the image, smoke-test it, push it to ACR,
attach it to the existing `cmms` web app with the non-secret application
settings, then confirm the site serves. There is no test environment, and
`test/*` tags build nothing.

It **does** write the non-secret application settings listed in §1. It never
writes secrets: the deploy task's `appSettings` adds or updates only the keys
it names, so `DB_PWD`, `JWT_SECRET_KEY`, `OAUTH2_CLIENT_SECRET` and anything
else set by hand survive every deploy (§2).

---

## 1. Deployment settings live in `.azure/env/prod.env`

**There is nothing to create in Azure DevOps Library.** Everything the pipeline
needs is committed in one file, and all of it is non-secret:

| Key | Value | What it does |
|---|---|---|
| `WEBAPP_NAME` | `cmms` | The existing web app the image is attached to |
| `WEBAPP_RESOURCE_GROUP` | `New-Implementations` | Where it lives |
| `IMAGE_REPOSITORY` | `cmms` | Repository in `enerkem.azurecr.io` |
| `PUBLIC_URL` | `https://cmms.enerkem.com` | **No trailing slash.** Compiled into the SPA bundle at image build time, pushed as `PUBLIC_API_URL`/`PUBLIC_FRONT_URL`, and polled after the deploy |
| `ENABLE_SSO` | `true` | Baked into the bundle; shows the SSO button |
| `OAUTH2_PROVIDER` | `microsoft` | Baked into the bundle |
| `WEBSITES_PORT` | `8080` | The platform probes this port; without it every request 504s |
| `SPRING_PROFILES_ACTIVE` | `prod` | |
| `DB_URL` | `10.225.1.104/atlas` | **host[:port]/db only** — `application.yml` prepends `jdbc:postgresql://`; pgJDBC defaults to 5432. An IP, not the FQDN; see §4 |
| `DB_USER` | `atlas` | |
| `STORAGE_TYPE` | `azure` | Selects `AzureBlobService` |
| `AZURE_STORAGE_ACCOUNT` | `stgcaneastcmms` | The existing storage account |
| `AZURE_STORAGE_CONTAINER` | `cmms` | The existing container |
| `OAUTH2_CLIENT_ID` / `OAUTH2_TENANT_ID` | `f08d1fe7-…` / `cddc5ffd-…` | Public identifiers, not secrets. The client id changed on 2026-09-15; the secret in Key Vault must belong to the SAME registration |
| `MAIL_TYPE` / `SMTP_HOST` / `SMTP_PORT` / `SMTP_FROM` | `SMTP` / `smtp.enerkem.com` / `25` / `noreply@enerkem.com` | Internal relay |
| `SMTP_AUTH` / `SMTP_STARTTLS` | `false` / `false` | The relay wants neither. `application.yml` hardcoded both to `true` upstream; it now reads these, defaulting to `true`. `SMTP_USER`/`SMTP_PWD` stay unset |
| `MAIL_RECIPIENTS` | `cmms-admins@enerkem.com` | Required even with mail off — no default in `application.yml` |
| `ENABLE_EMAIL_NOTIFICATIONS` / `INVITATION_VIA_EMAIL` | `true` / `true` | Invitations go out by email. If someone cannot get in, a silently-dropping relay is the first thing to check |
| `ENABLE_CORS` | `true` | Matches the repo-root `prod.env` |
| `LOG_FILE` | `/home/cmms/atlas.log` | Where `startup.sh` tees the console output, for reading over SSH |

The first six are **validated by name** and the run fails if any is empty;
`PUBLIC_URL` must additionally be `https://` with no trailing slash. Contrast
an Azure DevOps variable group, where an undefined `$(FOO)` is left as the
literal string `$(FOO)` — a forgotten variable silently fed garbage into a
build argument instead of failing the run.

Everything from `WEBSITES_PORT` down is pushed onto the web app as an
application setting by the deploy task. **Edit this file rather than the
portal**: the next release overwrites any portal edit to these keys.

⚠️ **`.azure/env/prod.env` is not the repo-root `prod.env`.** Two different
files, deliberately:

| | `prod.env` (repo root) | `.azure/env/prod.env` |
|---|---|---|
| Holds | the app's full runtime config for running **locally**, including secrets | non-secret deployment settings |
| In git | **never** — gitignored | **yes**, committed on purpose |
| In the image | no — `.dockerignore` excludes `*.env` | no |
| Read by | you, running locally | the pipeline |

They overlap on the URL, the SSO flags, the database host and the storage
account. **Change one, change the other.**

### What you still need in Azure DevOps

| Thing | Why |
|---|---|
| **Website Contributor** for the pipeline's service principal on `New-Implementations` | attach the image, push app settings, restart, download logs |

No variable group, no environment, no approval gate — the pipeline is a single
job, and the only thing that triggers it is you pushing a `release/*` tag.

---

## 2. Secrets: Key Vault, referenced from app settings

Secrets never go in this repo, never in the pipeline, and never as literal
application settings. They live in a **per-environment Key Vault**, and the app
settings hold a *reference* to them:

```
DB_PWD = @Microsoft.KeyVault(VaultName=enkm-cmms-prod;SecretName=db-password)
```

App Service resolves that at container start, as the app's managed identity.
Nothing sensitive reaches the repo, the state file, the pipeline, or anyone
reading the app's configuration.

| Vault | Environment |
|---|---|
| `enkm-cmms-prod` | prod |
| `enkm-cmms-test` | test |

**Neither vault exists yet** (checked 2026-09-11 — the only `cmms`-adjacent
vaults in the subscription belong to other apps). The OpenTofu module would
create them, but it has not been applied and must not be applied as-is (§4), so
create the prod one by hand with the name above. Using that exact name keeps a
future `tofu apply` able to adopt it instead of making a second vault.

### The secrets

| Secret | Required? | Notes |
|---|---|---|
| `db-password` | **yes** | `application.yml` gives `DB_PWD` no default — the app will not boot without it |
| `jwt-secret-key` | **yes** | No default either. Must be **strict base64 decoding to ≥32 bytes** — `JwtTokenProvider.init()` runs it through `Base64.getDecoder().decode()`, so a readable string with a `-` throws `Illegal base64 character 2d` and the context never starts. Use `openssl rand -base64 48`. Different per environment; rotating it logs everyone out |
| `oauth2-client-secret` | yes, if SSO is on | From the Entra app registration. **These expire** — record the date, because SSO starts failing when it lapses |
| `smtp-password` | **no** | Skip it while mail is off, and leave the `SMTP_PWD` app setting unset: `application.yml` declares `${SMTP_PWD:}`, so it defaults to empty. ⚠️ **Do not try to store an empty secret** — Key Vault rejects an empty value, so there is no "blank placeholder" option here |

### Setting it up, once

```powershell
.\scripts\setup-keyvault.ps1 -WhatIf    # review
.\scripts\setup-keyvault.ps1            # do it
```

The script reads the three secrets out of the **repo-root `prod.env`** (the
gitignored one) and does the whole sequence: creates the vault with RBAC and
purge protection, grants you *Key Vault Secrets Officer* and the web app's
identity *Key Vault Secrets User*, pushes the secrets, fixes
`keyVaultReferenceIdentity`, sets the three referencing application settings,
and reports whether each reference resolved.

It is idempotent — re-running it re-reads `prod.env` and updates any secret
whose value changed, which is also how you rotate.

Three things it handles that are easy to get wrong by hand:

- **Parsing.** It splits each line on the *first* `=` only. Base64 values are
  `=`-padded, so a naive split silently truncates `jwt-secret-key` and the app
  then dies at startup with `Illegal base64 character`.
- **Validation before writing.** `JWT_SECRET_KEY` is checked as strict base64
  decoding to ≥ 32 bytes, because `JwtTokenProvider.init()` runs it through
  `Base64.getDecoder().decode()` then `Keys.hmacShaKeyFor()`.
- **RBAC propagation.** A role assignment made seconds earlier may not have
  reached the data plane, so the first secret write is retried for a couple of
  minutes rather than failing with a bare `Forbidden`.

Microsoft Graph is blocked by Conditional Access in this tenant, so
`az ad signed-in-user show` fails; the script reads your object id from the
access token's `oid` claim instead.

### Checking it worked

```bash
az webapp config appsettings list --name $APP --resource-group $RG \
  --query "[?contains(value,'KeyVault')].name" -o tsv
```

The portal shows a green tick per resolved reference under
**Configuration → Application settings**. A red cross there is the single most
likely reason a container will not start.

### Managing them afterwards

Day to day this is where you work, and none of it needs a deploy:

| Task | How |
|---|---|
| Rotate a secret | `az keyvault secret set` with the same name — it creates a new *version*. The references above are **unversioned**, so the app picks up the new value on its **next restart**. No redeploy, no pipeline run |
| See history | `az keyvault secret list-versions --vault-name $V --name db-password` |
| Roll back | Re-set the old value as a new version, or pin the reference to a specific version by appending `;SecretVersion=<id>` |
| Who read what, when | Key Vault logs every access — send its diagnostics to `workspacenewimplementations9584` |
| Recover a deletion | Soft delete is on; purge protection on prod means a delete cannot be forced through for the retention period |

Because references are unversioned, **rotation is two commands and a restart**:
set the secret, `az webapp restart`. That is the main reason to prefer this over
literal app settings.

### The alternative, and why not

`itbudget` keeps its `DB_PASSWORD` as a plain application setting — so there is
in-house precedent, and it is one command instead of the above. But a literal
value is readable by anyone with Contributor on the app (it shows up in
`az webapp config appsettings list` in the clear), has no version history, no
access audit, and no recovery if overwritten. It is also the thing a future
`tofu apply` will silently replace with a reference. Use Key Vault.

---

## 3. Settings in the parked OpenTofu config

> ⏸ **Reference only.** `infra/` is parked (`infra/README.md`) and nothing
> here is live. The settings that *are* live come from `.azure/env/prod.env`
> (§1) and the secrets in §2. This section is kept so the intended end state
> is not lost, and it is what to reconcile against when OpenTofu is unparked.

The equivalents in `infra/envs/test/main.tf` and `infra/envs/prod/main.tf`:

| Setting | Current | Notes |
|---|---|---|
| `oauth2_client_id` | **`REPLACE-WITH-ENTRA-APP-CLIENT-ID`** | still a placeholder. The real value is live in `.azure/env/prod.env`; fill this in whenever the config is unparked |
| `oauth2_tenant_id` | `cddc5ffd-…` | the Enerkem directory. Required for a single-tenant registration, which rejects `/common` with `AADSTS50194` |
| `mail_recipients` | `cmms-admins@enerkem.com` | required even when mail is off — `application.yml` gives it no default |
| `enable_email_notifications` | `false` | turn on once SMTP is verified end to end |
| `invitation_via_email` | `false` | requires working mail; enabling it with broken SMTP locks new users out |
| `plan_sku` | `B2` test, `P1v3` prod | the JVM plus a cold-start Liquibase run needs the headroom |
| `db_name` | `atlastest` (test) / `atlas` (prod) | created out of band |
| `db_user` | `atlastest` / `atlas` | created out of band. Matches `prod.env` |
| `db_host` | test `10.225.1.107`; prod read from the private endpoint | prod is **not** a literal — it comes from `data.azurerm_private_endpoint_connection.prod_db`, so the server is referenced and never managed. See §4 |

Defaults for the rest — storage, SMTP host and port, CORS — are in
`infra/modules/cmms/variables.tf`.

Note the divergence to reconcile later: the parked config would create its own
`cmmsstorageprod001` storage account and a `cmms-prod` web app on a dedicated
P1v3 plan, whereas production actually runs on the hand-built `cmms` app using
the `stgcaneastcmms` account.

---

## 4. Prerequisites

Nothing deploys until these exist.

### Databases

**The two environments are on two different servers.** Both already exist, both
are owned by other teams, both are reached through a private endpoint in
`VNET-CanEast-Tier1/Prod-Tier1-BackEnd`, and neither is managed by our config.

| Environment | Server | Private-endpoint address | Database | User |
|---|---|---|---|---|
| test | `db-caneast-django-pmo-test` (RG `New-Implementations`) | `10.225.1.107` | `atlastest` | `atlastest` |
| prod | **`db-caneast-pmdms`** (RG `RG-CanEast-PMDMS`) | `10.225.1.104` | `atlas` | `atlas` |

Production's server is referenced in `infra/envs/prod/main.tf` as a **data
source** — `azurerm_postgresql_flexible_server` for its identity plus
`azurerm_private_endpoint_connection` for its address — so the config records
which server production talks to and fails fast if it moves, while never being
able to create, change or destroy it. `tofu destroy` cannot reach it.

Because it is read across resource groups, whoever runs `tofu plan` for prod
needs at least **Reader on `RG-CanEast-PMDMS`**.

The `atlas` database and its `atlas` role still have to be created on that
server by its owners. Each role needs DDL rights on its own database:
Liquibase runs the whole changelog on every boot and JPA validates the schema
afterwards.

**Addressed by IP, not by FQDN, and deliberately.** `db-caneast-pmdms` has
public network access disabled, and there is no
`privatelink.postgres.database.azure.com` private DNS zone linked to
`VNET-CanEast-Tier1`. So `db-caneast-pmdms.postgres.database.azure.com`
resolves — from inside the VNet exactly as from outside — through the
privatelink CNAME to the server's *public* address, which then refuses the
connection. `prod-pmdms` and `itbudget`, the other apps on that server, both
use the literal IP for the same reason. An IP is safe here because pgJDBC
defaults to `sslmode=prefer`: the connection is still encrypted and no
certificate hostname check is performed. Do not add `sslmode=verify-full`
without linking a private DNS zone and switching to the FQDN first.

Each environment's database password goes into that environment's vault as
`db-password`.

### VNet integration subnets — network team

One per environment, so each app can reach its database's private endpoint.
**`cmms` has no VNet integration today**, so it cannot reach either database:

- **/28 or larger**, delegated to `Microsoft.Web/serverFarms`
- in **`VNET-CanEast-Tier1`** (resource group `RG-CanEast-Tier1`, canadaeast) —
  regional VNet integration cannot cross regions, and this is the VNet holding
  the database's private endpoint
- free ranges at the time of writing: **`10.225.5.48/28`** and
  **`10.225.5.64/28`** (`10.225.5.0/28`, `.16/28` and `.32/28` are taken)

Suggested names, following the existing convention: `Dev-Tier1-CMMS` and
`Prod-Tier1-CMMS`.

This mirrors how the budget app reaches the same server — `itbudget` integrates
into `Dev-Tier1-PMOProject` with `vnetRouteAll` on, exactly what our config
sets. Pass each resource id to OpenTofu when you apply that environment, as
`TF_VAR_vnet_integration_subnet_id`.

They are not created by our config on purpose: they live in `RG-CanEast-Tier1`,
outside the blast radius we agreed on.

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

Now that the pipeline applies no infrastructure, the
`azureSubscriptionServiceConnection` principal only needs enough to read the
web app's configuration, restart it, and download its logs:

| Role | Where | Why |
|---|---|---|
| **Website Contributor** (Contributor also works) | `New-Implementations` | `az webapp show`, `az webapp config show`, `az webapp sitecontainers list`, `az webapp restart`, `az webapp log download` |

**Whoever runs `tofu apply` by hand** — the repo owner, as themselves — needs
what the pipeline used to:

| Role | Where | Why |
|---|---|---|
| **Contributor** | `New-Implementations` | create and manage the `cmms-*` resources |
| **User Access Administrator** | `New-Implementations` | the four role assignments per environment. Contributor alone cannot grant roles — **the one most likely to need a request** |
| **Storage Blob Data Contributor** | `enkmtfstate001` | the state backend uses `use_azuread_auth`, so state is read and written as you, not with an account key |
| **Reader** | `RG-CanEast-PMDMS` | prod reads the database server and its private endpoint as data sources |
| **Reader** | `RG-CanEast-Tier1` | the VNet integration subnet is passed in by id and read |

When these roles move back to the service principal, that is the point at which
`tofu apply` can return to the pipeline.

### OpenTofu state — once

```bash
cd infra/bootstrap && tofu init && tofu apply
```

Creates `enkmtfstate001` and its `tfstate` container. See `infra/README.md` for
migrating bootstrap's own state into it afterwards.

---

## 5. Releasing

**Production only.** One tag form ships anything:

```bash
git tag release/1.6.0-enerkem.1 && git push origin release/1.6.0-enerkem.1
```

Tags must carry the upstream release number they are built on. The first
pipeline step validates this against `UPSTREAM_VERSION` and fails otherwise:

| Tag | Result while `UPSTREAM_VERSION` is `1.6.0` |
|---|---|
| `release/1.6.0-enerkem.1` | deploys to production |
| `release/1.7.0-enerkem.1` | **rejected** — upstream v1.7.0 is not merged |
| `release/1.6.0` | **rejected** — no `-enerkem.<n>` counter |
| `release/v1.6.0-enerkem.1` | **rejected** — no `v` prefix |
| `test/1.6.0-enerkem.1` | **nothing happens** — the trigger only matches `release/*` |

There is no test environment, so there is no ship-to-test-first step. The
smoke test in the run is what stands in for it: the image has to boot and serve
the SPA on the agent before it can reach the registry.

### What a run does

**Build** — one `docker build` from the repository root. `api/Dockerfile` zips
the whole repo for AGPLv3 §13, then builds the entire Maven reactor inside
`maven:3.9.3-eclipse-temurin-17` (Node via `frontend-maven-plugin`, `npm ci`,
CRA production build, SPA copied into `classpath:/static`, fat jar packaged) and
lands on `eclipse-temurin:17-jre-noble`, which carries sshd on 2222 and
`api/container/startup.sh`. **Java 17 throughout** — newer JDKs break Lombok
here, so the version is pinned in the Dockerfile, not a variable.

⚠️ **There is no verification step.** Removed on 2026-09-15 by the owner's
decision: *"remove all the tests you do during the build. Just limit to build a
working container and deploy it. If it doesn't work we will fix it."* Nothing
starts the image or checks that it serves the SPA before it is pushed and
deployed — a broken image reaches production and is fixed forward.

**Publish** — the image is built carrying both of its final tags and pushed
as-is:

| Tag | Meaning |
|---|---|
| `:<version>` | immutable, e.g. `:1.6.0-enerkem.1`. **This is what the web app is pointed at**, so a rollback is one command rather than a rebuild |
| `:latest` | moves to the newest release, for `docker pull` and the registry UI. Nothing deploys from it |

**Deploy** — `AzureWebAppContainer@1` attaches
`enerkem.azurecr.io/cmms:<version>` to the existing `cmms` app and pushes the
non-secret application settings from §1, then restarts it. Same task and same
approach as `../budget`. Settings not named in that list are left untouched,
which is what keeps the Key Vault references from §2 intact across deploys.

Then an **informational** poll of the public URL for up to 3 minutes, and the
container log either way. The poll never fails the release — it only reports —
but it is worth keeping, because the deploy task returns as soon as the platform
accepts the request and a container that fails to start leaves the previous one
serving, which looks exactly like success. Three minutes because the app needs
roughly 90 s to reach "Started ApiApplication".

⚠️ **First run changes the app's shape.** `cmms` was created as a *site
containers* app (`linuxFxVersion` is the literal string `sitecontainers`).
`AzureWebAppContainer@1` sets `linuxFxVersion` to `DOCKER|<image>`, moving it
to the classic single-container model. Functionally identical for one container
on port 8080, but it is a change to a hand-built app. `azure-pipelines.yml`
carries a commented-out `az webapp sitecontainers update` alternative if you
would rather keep the site-containers shape.

Expect **15–25 minutes**, dominated by `npm ci` and the CRA build.

### Rollback

Every release also pushes an immutable `cmms:<version>` tag:

Because the app is pointed at an immutable `:<version>` tag, a rollback is just
pointing it at an older one — no rebuild:

```bash
az webapp config container set --name cmms --resource-group New-Implementations \
  --docker-custom-image-name enerkem.azurecr.io/cmms:1.6.0-enerkem.1
az webapp restart --name cmms --resource-group New-Implementations
```

(If the app is still in its original *site containers* shape, use
`az webapp sitecontainers update --container-name cmms --image …` instead.)

The next `release/*` tag will move it forward again, so follow a rollback by
fixing the problem and releasing a new version rather than leaving it pinned.

---

## 6. First-run order

1. Check `.azure/env/prod.env` — it is committed and already filled in (§1)
2. Grant the service principal **Website Contributor** on `New-Implementations`
4. `atlas` database and `atlas` role on `db-caneast-pmdms` (§4)
5. Get a subnet created in `RG-CanEast-Tier1` and add VNet integration to
   `cmms` (§4) — without it the app cannot reach the database at all
6. Entra app registration; redirect URI on the `cmms` hostname
7. Create the `enkm-cmms-prod` vault, grant the two roles, seed the three
   secrets, and **fix `keyVaultReferenceIdentity`** — all of §2
8. Tag `release/…` and watch the SPA poll. The pipeline pushes the non-secret
   application settings itself, so §7's list is handled except the secrets.

Steps 3–7 are all manual today. `infra/bootstrap` and `tofu apply` are only
needed once the OpenTofu path is picked back up in a later release.

---

## 7. What the `cmms` web app still needs

`cmms` exists and is running, but it has **no application settings beyond
`WEBSITES_ENABLE_APP_SERVICE_STORAGE`** and **no VNet integration**, so no
container can currently boot on it: eight of these have no default in
`application.yml` and the app exits at startup without them.

The list below is what `infra/modules/cmms/main.tf` would set. Until OpenTofu
is applied, set them by hand — and remember that a later `tofu apply` on a
reconciled config is what makes them permanent.

| Setting | Value | Notes |
|---|---|---|
| `WEBSITES_PORT` | `8080` | the platform probes this port. Already the site container's `targetPort`, but set it too for the classic path |
| `SPRING_PROFILES_ACTIVE` | `prod` | |
| `DB_URL` | `10.225.1.104:5432/atlas` | **host:port/db only** — `application.yml` prepends `jdbc:postgresql://`. See §4 for why an IP |
| `DB_USER` | `atlas` | |
| `DB_PWD` | Key Vault reference to `db-password` | |
| `JWT_SECRET_KEY` | Key Vault reference to `jwt-secret-key` | rotating it logs everyone out |
| `PUBLIC_API_URL` | `https://cmms.enerkem.com` | same value as `PUBLIC_URL` in `.azure/env/prod.env` and the `public_url` default. ⚠️ Neither the DNS record nor a hostname binding exists yet — see §4 |
| `PUBLIC_FRONT_URL` | the same URL | one jar serves both |
| `MAIL_RECIPIENTS` | `cmms-admins@enerkem.com` | required even with mail off |
| `STORAGE_TYPE` | `azure` | |
| `AZURE_STORAGE_ACCOUNT` / `AZURE_STORAGE_CONTAINER` | the storage account and container | the identity needs Blob Data Contributor **and** Blob Delegator, to sign downloads with a user delegation SAS |
| `ENABLE_SSO`, `OAUTH2_PROVIDER`, `OAUTH2_CLIENT_ID`, `OAUTH2_TENANT_ID`, `OAUTH2_CLIENT_SECRET` | see §3 | |
| `ENABLE_EMAIL_NOTIFICATIONS`, `INVITATION_VIA_EMAIL` | `false` | until SMTP is verified |
| `ENABLE_CORS` | `false` | single origin |
| `LOG_FILE` | `/home/cmms/atlas.log` | see below. Optional — the image defaults to exactly this |

Two more things about `cmms` as it stands:

- **`keyVaultReferenceIdentity` is `SystemAssigned`, but the app has no system
  assigned identity** — only the user-assigned `ua-id-9ca4`. Every Key Vault
  reference above will fail to resolve until this points at that identity, and
  an unresolvable reference stops the container from starting. §2 step 4 has the
  command.
- **No VNet integration**, so `10.225.1.104` is unreachable. This is the first
  thing to fix; see §4.

### Reading the log over SSH

The image now runs `api/container/startup.sh`, which mirrors
`../budget/container/startup.sh`:

- **sshd on port 2222**, root password `Docker!`, from
  `api/container/sshd_config` — the exact combination App Service's SSH console
  requires. It is not internet-reachable; the only route in is the
  authenticated SCM tunnel.
- The app runs in the foreground with its console output **teed to
  `$LOG_FILE`**, default `/home/cmms/atlas.log`. stdout is untouched, so
  `az webapp log tail` and Log Analytics keep working as before.
- A non-root `cmms` user (password `cmm5`, passwordless sudo) for poking around,
  matching budget's `budget` user.

```bash
az webapp ssh --name cmms --resource-group New-Implementations
# then, inside the container:
tail -f /home/cmms/atlas.log
```

The runtime base image changed from `amazoncorretto:17-alpine` to
`eclipse-temurin:17-jre-noble` to get the same apt/openssh setup budget uses.
Still Java 17 — newer JDKs break Lombok in this codebase.

`/home` is **not** persisted while `WEBSITES_ENABLE_APP_SERVICE_STORAGE` is
`false`, so `atlas.log` starts empty on every restart and holds only the
current container's output. That is usually what you want when diagnosing a
failed start. Set it to `true` if you need the log to survive restarts.
