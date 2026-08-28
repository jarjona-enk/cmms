# Cerebrum

> OpenWolf's learning memory. Updated automatically as the AI learns from interactions.
> Do not edit manually unless correcting an error.
> Last updated: 2026-08-28

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
- **App PostgreSQL is at `10.225.1.107`** — a private endpoint in
  `VNET-CanEast-Tier1/Prod-Tier1-BackEnd`. Apps address it **by IP**, not name
  (`itbudget` uses `jdbc:postgresql://10.225.1.107:5432/budget`). Safe because pgJDBC
  defaults to `sslmode=prefer`, which encrypts but skips hostname verification.
- App Service VNet integration uses one **/28 per app in `VNET-CanEast-Tier1`**
  (RG `RG-CanEast-Tier1`), delegated to `Microsoft.Web/serverFarms`, with `vnetRouteAll` on.
- `New-Implementations-vnet` (canadacentral) is a dead end: a single /24 fully delegated to
  PostgreSQL, wrong region for canadaeast apps.

### Azure DevOps / OpenTofu gotchas

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
- **Reuse `10.225.1.107`** (the budget app's server) rather than `db-cancen-it-poet-test`,
  which is VNet-injected in canadacentral where regional VNet integration cannot reach it.
- **Images are built per environment, never promoted**, because the public URL is baked into
  the SPA bundle.
