# Cerebrum

> OpenWolf's learning memory. Updated automatically as the AI learns from interactions.
> Do not edit manually unless correcting an error.
> Last updated: 2026-09-10

## User Preferences

- **Ask before acting on ambiguity, but never stall with nothing delivered.** The user
  explicitly says "stop if there is a blocking problem, ask me". Do the independent work
  first, then surface the blocker with options and a recommendation.
- **Mimic existing Enerkem patterns rather than inventing.** When asked for a pipeline the
  user pointed at `../itsheets/azure-pipelines-1.yml` and said "mimic that setup". Always
  look for a sibling project in `C:\data\src\` that already solves the problem.
- **Read the live Azure environment instead of asking for exports.** `az` CLI and the Azure
  MCP tools are authenticated against subscription `Enterprise`
  (`d14f7b8e-d71d-4106-ab93-990c96df467c`). Reading real resources beats guessing.
- **Infrastructure as code owns configuration**, not the pipeline and not the portal.
- **Narrow blast radius on shared infrastructure.** `New-Implementations` holds ~100
  resources from a dozen teams. Create only `cmms-*`; read everything else as data sources.
- **Keep REQUIREMENTS.md current** with every variable and instruction the user must action.
- Prod gets an approval gate; test deploys straight through.
- Terse, factual reporting. State what was verified vs. assumed.
- **OpenTofu is PARKED and the pipeline is PRODUCTION-ONLY.** Decided
  2026-09-11, superseding the 2026-09-10 version of this: infrastructure was
  built by hand and is ready, `infra/` must not be applied (it would build a
  parallel environment), and there is no test environment at all. The pipeline
  builds a container, pushes it, and attaches it to the existing `cmms` app.
  Do not reintroduce a `tofu` step, a test stage, or an environment gate.
- **`Docker@2` with `command: buildAndPush` IGNORES the `arguments` input.** So
  it cannot pass `--build-arg`. For this repo that would silently bake
  `localhost:8080` into the SPA bundle. Use `command: login` plus a plain
  `docker build`/`docker push`, which is why this pipeline diverges from
  itsheets and budget on that one point.
- **`AzureWebAppContainer@1` sets `linuxFxVersion`**, so pointing it at a *site
  containers* app converts that app to the classic single-container model. Use
  `az webapp sitecontainers update --container-name <n> --image <img>` to set
  the image without changing the shape.
- **Existing resources owned by other teams are referenced, never managed.**
  Data sources are welcome; `resource` blocks for them are not.
- **Prefers configuration in committed files over Azure DevOps variable groups
  and portal settings.** Asked directly whether a file could replace the
  variable group (2026-09-11). Same instinct as "infrastructure as code owns
  configuration": if it is not secret, it belongs in git where it is
  reviewable. Corollary: do NOT solve that by shipping a secret-bearing env
  file to CI — give the pipeline only what it needs.
- **Mirror `../budget` for container-level concerns** (sshd, log file, startup
  script), the same way the pipeline mirrors `../itsheets`. When the user says
  "exactly as they are on budgets", copy the files rather than reinventing.
- The user renames/creates Azure resources by hand between sessions. **Read the
  live environment before touching anything that names a resource** — `cmms`
  replaced `cmms-prod` with no repo change.

## Key Learnings

### This is a downstream fork — read CLAUDE.md before any git operation

- `origin` = Azure DevOps `EnerkemIT/New Services Implementations/cmms` (HTTPS + PAT via Git
  Credential Manager; SSH keys are not registered). `upstream` = `github.com/Grashjs/cmms`
  with push URL literally `DISABLED`.
- `main` is the Enerkem line and the Azure DevOps default branch. Upstream is never mirrored
  to a local branch.
- **Merge policy: upstream release tags only, one at a time, oldest first, always merge never
  rebase.** `upstream/main` sits 279 commits past their last tag.
- Never push upstream `v*` tags to `origin` — a tag newer than the merge base drags its whole
  unreleased history in. This is why CI reads `UPSTREAM_VERSION` instead of `git describe`.
- Release tags: `test/<upstream>-enerkem.<n>` and `release/<upstream>-enerkem.<n>`.

### Build

- **JDK 17** (`C:\java\jdk-17`). Machine default JDK 26 breaks Lombok.
- **Only `mvnw.cmd` exists in `api/`** — there is no POSIX `mvnw`. Run builds through the
  PowerShell tool, not Bash.
- **`npm ci`, never `npm install`** — the latter drifts i18next into `TS2339`.
- One fat jar `api/target/app.jar` serves the REST API and the React SPA on one port.

### Application architecture

- `REACT_APP_API_URL` / `ENABLE_SSO` / `OAUTH2_PROVIDER` are **compiled into the CRA bundle at
  image build time**, so an image is specific to one environment and cannot be promoted.
  `frontend/src/config.ts` has a `window.__RUNTIME_CONFIG__` fallback, but build-time env wins
  and `runtime-env.js` does not exist.
- **`FileMapper` turns every file reference into a signed URL**; the API never proxies file
  bytes. So object storage must be reachable from end-user browsers, not just the app.
  Signatures are host-bound.
- `MinioService.init()` builds its client on **`PUBLIC_MINIO_ENDPOINT`**, not `MINIO_ENDPOINT`.
  The latter is only an HTTP proxy target used when the public endpoint is localhost.
- Storage backends are `azure`, `minio` (S3 API) and `gcp`. **Azure Blob cannot be used via
  `minio`** — the MinIO SDK speaks S3 and Blob has no S3 endpoint.
- Required-or-the-app-won't-boot env vars (no default in `application.yml`): `DB_URL`,
  `DB_USER`, `DB_PWD`, `JWT_SECRET_KEY`, `PUBLIC_API_URL`, `PUBLIC_FRONT_URL`,
  `MAIL_RECIPIENTS`, `STORAGE_TYPE`. `DB_URL` is `host:port/db` — the `jdbc:postgresql://`
  prefix is added by `application.yml`.
- `/health-check` uses `CustomHealthIndicator`, which always returns UP — it proves the context
  started, nothing more.

### Enerkem Azure environment

- One flat resource group **`New-Implementations`** (canadaeast) holds nearly everything.
- Registry **`enerkem.azurecr.io`**, Log Analytics `workspacenewimplementations9584`.
- Web apps are named `<env>-<app>`; storage `<app>storage<env>001`; vaults `<app>-<env>`.
  Custom domains `<app>.enerkem.com` with App Service certificates.
  **CMMS breaks this:** the production app is plain **`cmms`**, not `prod-cmms`,
  and the custom domain `cmms.enerkem.com` does **not exist yet** (NXDOMAIN, no
  hostname binding as of 2026-09-11). A custom domain here is manual work — the
  OpenTofu module creates no hostname binding.
- **Three postgres private endpoints live in
  `VNET-CanEast-Tier1/Prod-Tier1-BackEnd`, and they are not the same server.**
  Verified 2026-09-10:

  | PE | IP | server | region |
  |---|---|---|---|
  | `DevPostgresDB` | `10.225.1.107` | `db-caneast-django-pmo-test` | canadacentral |
  | `PrivateEndpointPostgreSQL` | `10.225.1.100` | `db-caneast-django-pmo-test` | canadacentral |
  | `PMDMSPrivateEndpointPostgreSQL` | `10.225.1.104` | `db-caneast-pmdms` (RG `RG-CanEast-PMDMS`) | canadaeast |

  `itbudget` uses **`10.225.1.104`** (`jdbc:postgresql://10.225.1.104:5432/budget`),
  as does `prod-pmdms` (`POSTGRES_HOST`). CMMS **prod** uses it too. CMMS test
  still points at `10.225.1.107`, which is a *test* server.
- **Apps address these servers by IP, never by FQDN, and they have to.** No
  `privatelink.postgres.database.azure.com` private DNS zone exists in the
  subscription, and `VNET-CanEast-Tier1` uses corporate DNS (`10.250.0.11/12`).
  So `<server>.postgres.database.azure.com` resolves inside the VNet exactly as
  outside — via the privatelink CNAME to the server's PUBLIC address (verified:
  `db-caneast-pmdms` → `52.229.73.241`), which refuses connections because
  public access is disabled. Safe because pgJDBC defaults to `sslmode=prefer`:
  encrypted, no hostname check. **Before writing an Azure DB FQDN into a
  config, check that a private DNS zone exists and is linked to the app's
  VNet.**
- **Some Enerkem web apps are "site containers" apps.** `cmms` reports
  `linuxFxVersion == "sitecontainers"` — a literal string, not `DOCKER|…`; the
  image lives on the main site container instead, read with
  `az webapp sitecontainers list --query "[?isMain].image"`. Anything parsing
  `linuxFxVersion` to find the running image must handle both shapes.
- **`AZURE_CLIENT_ID` and `OAUTH2_CLIENT_ID` are different principals.**
  `AZURE_CLIENT_ID` = the user-assigned managed identity `ua-id-9ca4`
  (`dbb349c1-…`), used by the Azure SDK for the app to authenticate *itself*;
  it holds every Azure RBAC role we granted. `OAUTH2_CLIENT_ID`
  (`635e54c9-…`) is the Entra app registration for *users* signing in and holds
  no Azure roles. With ONLY a user-assigned identity attached,
  `DefaultAzureCredential` fails with "Managed Identity authentication is not
  available" unless `AZURE_CLIENT_ID` names it.
- **`AzureBlobService.init()` calls `containerClient.exists()` at startup**, so
  any storage auth or network failure kills the `storageServiceFactory` bean and
  the whole Spring context. Storage problems present as a boot failure, not as a
  broken file feature.
- **App Service "Container exited with exit code 0" can be a lie.**
  `api/container/startup.sh` ends in `java ... | tee`, and a pipeline returns
  its LAST command's status, so the script always exits 0 however java died.
  Read the app's real output from
  `LogFiles/StartupLogs/<date>_<host>_failure.log` (the `ContainerStream:`
  lines) — it is NOT in docker.log for the most recent attempt.
- **App Service stops a site after repeated cold-start failures** ("Site is
  blocked due to multiple, consecutive cold start failures", then "Site
  stopped"). A log that looks current can therefore predate a fix by hours,
  because nothing retried. Check the web app's `state` before concluding a fix
  did not work.
- **PostgreSQL 15+ does not grant CREATE on `public` to PUBLIC.** Owning the
  *database* is not enough: the `public` schema inside it can still be owned by
  `azure_pg_admin`, leaving the app role with USAGE only. This app runs
  Liquibase on every boot with `ddl-auto: validate`, so it fails at startup with
  `permission denied for schema public`. Fix:
  `ALTER SCHEMA public OWNER TO <role>; GRANT ALL ON SCHEMA public TO <role>;`
  Check with `has_schema_privilege('<role>', 'public', 'CREATE')`, and verify by
  actually creating a table under `SET LOCAL ROLE`, not by reading the ACL.
- **The `intellij` MCP server does not connect here; the `idea` one does.**
  Database tools are `mcp__idea__*`. There is a working datasource
  *Production CA-CENTRAL* pointed at `10.225.1.104:5432` (the prod server),
  connecting as `enk_pg_admin`, who is a member of both `atlas` and
  `azure_pg_admin`.
- **`JWT_SECRET_KEY` must be strict base64 decoding to ≥32 bytes.**
  `JwtTokenProvider.init()` does `Base64.getDecoder().decode(secretKey)` then
  `Keys.hmacShaKeyFor()`. A readable string with a `-` throws
  `IllegalArgumentException: Illegal base64 character 2d` and the context never
  starts. Use `openssl rand -base64 48`.
- **The AGPLv3 source bundle is built from the Docker build context**, so
  `.dockerignore` is what keeps secrets and junk out of a zip served publicly
  at `GET /source-code/download`. It is not just a build-speed file.
- **On Windows `az` is az.cmd, so cmd.exe re-parses every argument.** A value
  containing `;` `(` `)` or `&` - a Key Vault reference
  `@Microsoft.KeyVault(VaultName=v;SecretName=s)` has three of them - gets torn
  apart, with an error like "JWT_SECRET_KEY was unexpected at this time". No
  PowerShell quoting helps. Pass such values through a file: for app settings,
  `--settings @file.json` with `[{name,value,slotSetting}]`.
- **Redact secrets in error paths, not just in success output.** An error
  handler that echoes the failed command line will print `--value <secret>`
  into the console and any transcript. Keep a redaction list and filter every
  message through it.
- **PowerShell: never name a function parameter `$Args`, and avoid advanced
  functions for `az` wrappers.** An advanced function tries to bind a
  leading-dash token as its own parameter, so `-o json` dies with "the
  parameter name 'o' is ambiguous" (it matches `-OutVariable`/`-OutBuffer`).
  Use a simple function with no `param()` block so everything lands in the
  automatic `$args`.
- **Parsing a .env file: split on the FIRST `=` only.** Base64 values are
  `=`-padded, so splitting on every `=` silently truncates keys like
  `JWT_SECRET_KEY` and the app then fails at startup with `Illegal base64
  character`.
- **`SMTP_AUTH` / `SMTP_STARTTLS` were inert until 2026-09-11.**
  `application.yml` hardcoded `properties.mail.smtp.auth: true` and
  `starttls.enable: true`; they are now `${SMTP_AUTH:true}` /
  `${SMTP_STARTTLS:true}`, defaults unchanged. The relay is
  `smtp.enerkem.com:25`, unauthenticated, no TLS. Beware the **second, stray
  `properties.mail.smtp` block indented under `spring.jpa`** in the same file:
  upstream noise, handed to Hibernate, does nothing — do not "fix" it there and
  think mail is configured.
- **`spring.mail.from` is read by `@Value` in `EmailService2`,** not by
  `MailProperties` binding — so `SMTP_FROM` does work, even though `from` is
  not a MailProperties field.
- **Azure Key Vault will not store an empty secret value.** So "set it blank as
  a placeholder" is not an option; either store a real value or omit the
  reference and let the app's own default apply. `SMTP_PWD` is
  `${SMTP_PWD:}` in `application.yml`, so omitting it is correct while mail is
  off. `DB_PWD` and `JWT_SECRET_KEY` have no defaults and are boot-critical.
- **Key Vault references must be unversioned** (`VaultName=…;SecretName=…`, no
  `SecretVersion`) so rotation takes effect on the next restart instead of
  needing a redeploy. And `keyVaultReferenceIdentity` must name the identity
  that actually exists — on `cmms` it says `SystemAssigned` while only a
  user-assigned identity is attached, which makes every reference fail and the
  container refuse to start.
- App Service VNet integration uses one **/28 per app in `VNET-CanEast-Tier1`**
  (RG `RG-CanEast-Tier1`), delegated to `Microsoft.Web/serverFarms`, with `vnetRouteAll` on.
- `New-Implementations-vnet` (canadacentral) is a dead end: a single /24 fully delegated to
  PostgreSQL, wrong region for canadaeast apps.

### Azure DevOps / OpenTofu gotchas

- **A tag-only Azure DevOps trigger must name the tag ref in
  `branches.include`.** `branches: {exclude: ['*']}` plus a separate
  `tags: {include: [...]}` block fires **nothing** - the tag push queues no run
  at all, with no error anywhere. Use
  `branches: {include: ['refs/tags/release/*']}`; ordinary branches cannot match
  it. Verified the hard way on 2026-09-13 (`bug-034`).
- **`reason: manual` on a run means someone clicked *Run pipeline*,** which
  queues against the default branch. For a tag-triggered pipeline that can never
  succeed, so check `az pipelines runs show --id <n> --query reason` before
  concluding the trigger is broken.
- **Service connections are PROJECT-SCOPED.** Ids copied from another project's
  pipeline silently do not resolve. In "New Services Implementations" the right
  ones are `784814e7-...` (`DEVOPS - ACR` -> registry `enerkem`) and
  `ca8fb3b0-...` (`Enterprise`). `Docker Registy connector` (`b50e431e-...`)
  points at `sjusiccontainerregistry` and is the wrong registry.
- **A service connection may be granted per-pipeline rather than to all
  pipelines.** Check with
  `az devops invoke --area pipelinePermissions --resource pipelinePermissions
  --route-parameters project=<p> resourceType=endpoint resourceId=<id>
  --api-version 7.1-preview`; PATCH the same route to authorise one. Note the
  api-version must be `7.1-preview`, not `7.1-preview.1`, or the CLI throws
  "could not convert string to float".
- **Microsoft Graph is blocked by Conditional Access in this tenant.**
  `az ad sp show`, `az ad signed-in-user show` and the name-resolution inside
  `az role assignment list` all fail with AADSTS53003. Work around it: read
  role assignments through `az rest` on the ARM authorization API, address
  principals with `--assignee-object-id` + `--assignee-principal-type`, and get
  your own object id from the `oid` claim of
  `az account get-access-token`.
- **Creating a pipeline twice is easy and dangerous.** Two definitions pointing
  at the same repo and YAML both trigger on the same tag and race each other
  onto the same web app. Check `az pipelines list` before a first run.

- **An undefined `$(VAR)` is left as the literal string `$(VAR)`** — a missing variable does
  not fail the build, it writes garbage. Every referenced variable must exist, blank if unused.
- `AzureWebAppContainer@1` and `az webapp restart` return as soon as the platform accepts the
  request; a container that fails to start leaves the previous one serving. Always poll the
  public URL afterwards.
- Approval gates attach to **environments**, which requires a `deployment` job.
- `tofu`/`terraform` are not installed by default; `winget install OpenTofu.Tofu` works but the
  binary is not on PATH in the current shell — invoke it by full path under
  `%LOCALAPPDATA%\Microsoft\WinGet\Packages\OpenTofu.Tofu_*\tofu.exe`.

## Do-Not-Repeat

- **[2026-09-11]** Broke the shell with a quote-heavy python heredoc for the
  THIRD time in two days (`syntax error near unexpected token '('` on text
  containing `$(...)`). The rule is not "be careful with heredocs", it is
  **write the script to the scratchpad with the Write tool and run it by
  path** whenever the content contains backticks, `$(`, or markdown.

- **[2026-09-10]** Wrote a preflight in `.azure/steps-deploy.yml` that compared
  against `$(targetEnv)` / `$(releaseVersion)`. Those are set with
  `task.setvariable` in the **Build** stage, and task.setvariable is
  **job-scoped** — they arrive empty in another stage. Either publish them as
  output variables or re-derive them from `$(Build.SourceBranch)`, which every
  stage can see. Chose the latter.
- **[2026-09-10]** Claimed `itbudget` uses `10.225.1.107`. It uses
  `10.225.1.104`. Read the actual app settings (`az webapp config appsettings
  list`) instead of trusting an earlier note.
- **[2026-09-10]** Asserted "nothing pulls `:latest`, it must never be what a
  web app tracks" in a pipeline comment, one step after being told to push
  `:latest` — and the `cmms` app pulls exactly that. Check what the live app is
  configured with before writing a comment about what "nothing" does.
- **[2026-09-10]** Concluded sshd was not listening from a `docker exec ss …`
  check: `ss` is in iproute2, which is not installed (budget installs
  net-tools, so it is `netstat`). A missing tool reads exactly like a failing
  service — verify the tool exists before believing the negative result.
- **[2026-09-10]** Broke the shell *again* with a python heredoc containing
  markdown tables and quotes, despite the 2026-08-28 entry saying not to. For
  anything with mixed quoting, write the script to the scratchpad with the
  Write tool and run it by path.

- **[2026-08-28]** Documented Azure Blob Storage as a `MINIO_ENDPOINT` value. It can never
  work — the MinIO SDK speaks S3 and Blob exposes no S3 endpoint. Check that an SDK can
  actually talk to a service before writing it into a config example.
- **[2026-08-28]** Described `MINIO_ENDPOINT` as "the URL the server uses". Wrong: the client
  is built on `PUBLIC_MINIO_ENDPOINT`. Read the `@PostConstruct`/`init()` before documenting
  what a config value does.
- **[2026-08-28]** Wrote the OpenTofu module with a **system-assigned** identity. `tofu
  validate` rejected it as a cycle: role assignments need the app's principal id, but the app
  needs AcrPull and Key Vault access before it starts. Use a **user-assigned** identity, and
  set `key_vault_reference_identity_id` + `container_registry_managed_identity_client_id`.
- **[2026-08-28]** Claimed upstream had no release tags ahead of our base, from a stale tag
  list. `v1.7.0` and `v1.8.0` existed. Run `git fetch upstream --tags` before reasoning about
  upstream position.
- **[2026-08-28]** Ran `tofu fmt` and then applied a string replacement that no longer matched,
  because fmt had realigned `DB_URL =` to `DB_URL  =`. Re-grep after formatting, and always
  re-run `tofu validate` after a bulk edit.
- **[2026-08-28]** Tried to write a large YAML file with a bash heredoc; the mixed quoting
  broke the shell and the file was never created. Use the Write tool for anything large or
  quote-heavy.
- **[2026-08-28]** Ran `./mvnw` from `api/`. Only `mvnw.cmd` exists — use the PowerShell tool.
- **[2026-08-28]** Assumed `../budgets` existed; the directory is `../budget`. Check sibling
  project names before referencing them.

## Decision Log

- **`main` is the Enerkem line, not an upstream mirror.** Once `origin` became a separate
  Azure DevOps repo, making its default branch a copy of Grashjs code would point CI, PRs and
  clones at the wrong thing. Upstream lives only as the `upstream/main` ref plus tags.
- **`.idea/` stays tracked.** Upstream has zero commits touching it, so the conflict risk is
  nil, and the files carry the JDK 17 + Lombok annotation-processor setup the build needs.
- **Tag format `<upstream>-enerkem.<n>`**, chosen by the user over `1.6.0.N` and bare `1.6.0`.
  It makes the upstream base unambiguous and stays a legal Docker tag. Enforced by the
  pipeline against `UPSTREAM_VERSION`.
- **OpenTofu owns the application settings**, not the pipeline. The two would otherwise fight
  over the same settings on every deploy, each reverting the other.
- **Secrets are seeded into Key Vault by hand; Tofu never reads them.** App settings hold
  literal `@Microsoft.KeyVault(...)` reference strings, so no secret reaches the state file or
  the pipeline. Cost: the vault must be seeded between the first apply and the first deploy.
- **Storage account stays publicly reachable, database stays private.** Browsers fetch
  attachments directly via SAS, so locking storage to the app's subnet would break every image.
- **VNet subnets are created out of band**, not by our config — they live in
  `RG-CanEast-Tier1`, outside the agreed blast radius.
- **Prod reuses `db-caneast-pmdms`** (`10.225.1.104`, RG `RG-CanEast-PMDMS`) — the
  server `itbudget` and `prod-pmdms` already use — rather than
  `db-cancen-it-poet-test`, which is VNet-injected in canadacentral where regional
  VNet integration cannot reach it. Referenced as data sources only; the resource is
  never managed. Superseded the earlier note that named `10.225.1.107`, which is
  actually `db-caneast-django-pmo-test`, a test server. **[corrected 2026-09-10]**
- **Images are built per environment, never promoted**, because the public URL is baked into
  the SPA bundle.
- **[2026-09-10] Production database is `atlas`, production URL is
  `https://cmms.enerkem.com`.** `db_name = "atlas"` in `infra/envs/prod/main.tf`
  and `public_url` now defaults to that URL there, rather than depending on
  `TF_VAR_public_url` — the pipeline no longer supplies it. `db_user` is
  `atlas` as well, matching `prod.env`; production no longer follows the
  old user-matches-database `atlasprod` convention, though test still does.
  Open: `cmms.enerkem.com` has no DNS record or hostname binding yet (verified
  NXDOMAIN), and it must be settled before the first image build, because CRA
  compiles the URL into the SPA bundle.
- **[2026-09-11] OpenTofu parked; hand-built infrastructure is the reality.**
  Production is the hand-made `cmms` web app plus the `stgcaneastcmms` storage
  account, `atlas`/`atlas` on `db-caneast-pmdms`, and a Key Vault for secrets.
  `.azure/env/prod.env` is the live source of truth for deployment settings;
  `infra/` is reference-only until someone reconciles it. Open question at the
  time of writing: `stgcaneastcmms` has public network access disabled, which
  breaks the browser-side SAS download path the app depends on.

