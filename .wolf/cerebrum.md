# Cerebrum

> Active rules only (token-lean). Full prior text and everything trimmed lives in `.wolf/cerebrum-archive.md`: GREP it, never read it whole.
> Duplicates of CLAUDE.md (branch model, merge policy, tag format, build basics, tofu parked) are NOT repeated here.
> Last updated: 2026-10-29

## User Preferences

- **Ask on ambiguity, but never stall with nothing delivered:** do the independent work first, then surface the blocker with options and a recommendation.
- **Mimic existing Enerkem patterns** (`../itsheets/azure-pipelines-1.yml`, `../budget` for sshd/log/startup): look for a sibling project in `C:\data\src\` and copy rather than invent.
- **Config in committed files, IaC owns config** (not pipeline, portal or variable groups); never ship a secret-bearing env file to CI. Keep REQUIREMENTS.md current with every variable/instruction the user must action.
- **Narrow blast radius:** `New-Implementations` is shared by ~a dozen teams; create only `cmms-*`, others are data sources, never managed. The user renames/creates Azure resources by hand: read the live environment before naming a resource.
- Terse, factual reporting; state what was verified vs assumed.
- **LOCAL ONLY (owner, 2026-10-19):** no `az`, no prod/Azure reads or changes, no pushes to `origin`, no tags; the owner does those. Local Postgres, Docker and the `fork` remote (`contrib/*` only) are the playground. v1.9.0/Azure decisions are in ENERKEM-PLAN.md -> Decisions; do not re-ask.
- **Owner tags and pushes releases.** Hand-off: stop local processes, save memory/docs, commit, report the exact tag (`release/<upstream>-enerkem.<n>`) and stop. (Older text said "commit on main"; CLAUDE.md says work on `enerkem`.)
- **Roadmap = `ENERKEM-PLAN.md`** (numbered prompts; read it when the owner pastes one; each ends by updating DEVELOPMENT-STATUS). Upstream PR of the Azure backend is the ONE sanctioned upstream exception. Upstream-PR commits: author `Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>` via `git -c user.name/email`, `contrib/*` only; remote `fork` (`git@github.com:jarjona-enk/cmms.git`, key `~/.ssh/jarjona-enk`) gets `contrib/*` only, only when the owner says push; no `gh`.
- **Session start:** branch = enerkem; `curl localhost:2375/_ping` = 200; `docker ps` shows cmms-minio + cmms-mailhog; disk >= 10 GB; read ENERKEM-PLAN.md + latest DEVELOPMENT-STATUS.
- **`mvn test` is the gate** (863 tests, 1 expected failure: usage-limit test vs our AGPL decision; @Disabled it, never restore the limit). Run from `api/` ONLINE the first time, JDK 17, `-DskipFrontend=true`. Testcontainers on Docker Desktop 29 needs TCP 2375 + `DOCKER_HOST=tcp://localhost:2375` + `api.version=1.44` in `%USERPROFILE%\.docker-java.properties`. MinIO image `bitnamilegacy/minio:latest`. No AzureBlobService tests yet (Prompt 3: Mockito + Azurite IT).
- **The pipeline runs NO tests (2026-09-15):** build, push, deploy. Do not add a smoke test or make the post-deploy check fail the release. Tag/UPSTREAM_VERSION and env-key validation stay. (CLAUDE.md 2b still says "smoke-test": this decision is newer.)
- **Pipeline is PRODUCTION-ONLY, OpenTofu PARKED (2026-09-11):** no `tofu` step, test stage or environment gate; `infra/` is not applied.
- Prod production DML: NOT via the IntelliJ MCP (`mcp__idea__execute_sql_query` DELETE/UPDATE time out). Use `psql -h 10.225.1.104 -U atlas -d atlas` with `DB_PWD` from gitignored repo-root `prod.env` (VPN); always `RETURNING` + follow-up SELECT. The `idea` MCP works (datasource Production CA-CENTRAL, user `enk_pg_admin`); `intellij` does not.
- **Invitation mails go To: the invitee only; the admin copy is a separate mail sent on REGISTRATION (and SSO first login), never on invite/resend.**
- Mail = Exchange Online Direct Send: `smtp.enerkem.com:25`, no auth, recipients must exist in the tenant (else `550 5.4.1`). "Invalid credentials" in atlas.log is `UserService.signin`, never SMTP.
- **Spring traps (2026-09-16):** `@Async` on a same-class call is NOT async; `MailSendException` is unchecked and slips past `catch (MessagingException | IOException)`; class-level `@Transactional` on a throwing service marks the caller's tx rollback-only -> `@Transactional(NOT_SUPPORTED)` for mail/IO services (removing it can switch to a JDK proxy and break concrete injection of `EmailService2`).
- **"Unreachable" is DNS until proven otherwise:** compare `nslookup <host> 10.250.0.11` vs `1.1.1.1`, then `curl --resolve host:443:IP`. A 503 from an App Service private IP = hostname not bound behind THAT endpoint. `RG-CanEast-Tier1` is read-denied; ask the network team for PE IPs.
- **Shell/tool hygiene:** NEVER heredoc-fed Python or quote-heavy YAML (broke 5+ times): write scripts to the scratchpad with the Write tool and run by path. Parallel edits to one file race: serialize. Never pipe `docker run` into `head`. Git Bash curl.exe mangles UTF-8: use `--data-binary @file`. Maven from `api/` via PowerShell (`& $mvn -f ..\pom.xml ...`), only `mvnw.cmd` exists.
- **NEVER `taskkill //IM java.exe`:** another session (cybermap) does it and kills CMMS/Maven silently. Kill by PID from `netstat -ano | grep :PORT`; if java dies with no trace, check other sessions' transcripts.
- **Upstream merges:** check `.git/MERGE_HEAD` against the requested tag before resolving anything; bump UPSTREAM_VERSION in the same merge commit. SSO role lookup: upstream's typed API + our `orElseThrow`. `unaccent` must be allow-listed in `azure.extensions` (done on `db-caneast-pmdms`).
- **Local run** (`scratchpad/run-local.sh`): JDK 17, port 8085, pass `MAIL_RECIPIENTS` and `ENABLE_EMAIL_NOTIFICATIONS=false`, MinIO `cmms-minio` for `STORAGE_TYPE=minio`, override `PUBLIC_API_URL`/`PUBLIC_FRONT_URL`. Local `atlas` role cannot CREATE DATABASE: wipe `public` schema, keep a `pg_dump -Fc`. Stale gitignored SPA in `api/src/main/resources/static/`: `git clean -fdX` it (keep `source/`).

## Key Learnings

- **Build-time vs runtime:** `REACT_APP_API_URL`/`ENABLE_SSO`/`OAUTH2_PROVIDER` are compiled into the CRA bundle at image build (images per environment, never promoted).
- **Storage:** `FileMapper` returns signed URLs, so object storage must be browser-reachable (SAS, host-bound); `MinioService` builds on `PUBLIC_MINIO_ENDPOINT`; Azure Blob cannot go through `minio` (S3 API). `AzureBlobService.init()` calls `containerClient.exists()`: storage auth/network failure = boot failure.
- **Required env vars (no default):** `DB_URL` (`host:port/db`, no jdbc prefix), `DB_USER`, `DB_PWD`, `JWT_SECRET_KEY`, `PUBLIC_API_URL`, `PUBLIC_FRONT_URL`, `MAIL_RECIPIENTS`, `STORAGE_TYPE`. `JWT_SECRET_KEY` = strict base64 of >=32 bytes (`openssl rand -base64 48`). Parse .env splitting on the FIRST `=` only.
- **Azure:** prod app is plain `cmms` (site-containers app: `linuxFxVersion=="sitecontainers"`; read image via `az webapp sitecontainers list --query "[?isMain].image"`; set it with `az webapp sitecontainers update`, NOT `AzureWebAppContainer@1`). `cmms.enerkem.com` had no DNS/binding as of 2026-09-11. Prod DB `atlas`/`atlas` on `db-caneast-pmdms` `10.225.1.104` (itbudget and prod-pmdms too; `.107` is a TEST server); address DB by IP, never FQDN (no privatelink DNS zone). Check a private DNS zone exists before writing any Azure FQDN.
- **Settings/secrets:** the deploy pushes every key in `.azure/env/prod.env` each release (portal edits get reverted; edit the file). Rotating a secret = edit repo-root `prod.env`, run `scripts/setup-keyvault.ps1`, restart. Key Vault refs are unversioned; `keyVaultReferenceIdentity` must name the attached identity; KV cannot store empty values (omit `SMTP_PWD`). `AZURE_CLIENT_ID` = managed identity `ua-id-9ca4`, `OAUTH2_CLIENT_ID` = Entra user-login app: different principals.
- **Startup diagnosis:** "exit code 0" can lie (`startup.sh` pipes java into `tee`): read `LogFiles/StartupLogs/<date>_<host>_failure.log`. App Service stops a site after repeated cold-start failures: check `state` before concluding a fix failed. Always poll the public URL after deploy/restart (previous container keeps serving).
- **PostgreSQL 15+:** `public` schema may stay owned by `azure_pg_admin` -> `permission denied for schema public` (Liquibase on boot). Fix `ALTER SCHEMA public OWNER TO <role>; GRANT ALL ...`; verify by creating a table under `SET LOCAL ROLE`.
- **Windows `az` = az.cmd:** values with `; ( ) &` (KV references) get torn apart; pass via `--settings @file.json`. PowerShell: never name a param `$Args`, avoid advanced functions for `az` wrappers. Redact secrets in error paths too.
- **SMTP:** `SMTP_AUTH`/`SMTP_STARTTLS` are env-driven since 2026-09-11 (defaults true); relay is unauthenticated, no TLS. The stray `mail.smtp` block under `spring.jpa` in application.yml is inert: do not "fix" it there. `spring.mail.from` is read by `@Value` in `EmailService2` (`SMTP_FROM` works).
- AGPL source bundle (`/source-code/download`) is built from the Docker context: `.dockerignore` keeps secrets out.
- **Azure DevOps:** tag-only trigger needs `branches: {include: ['refs/tags/release/*']}` (the exclude-`*` + `tags` form fires nothing, bug-034); `reason: manual` = someone clicked Run (default branch). Service connections are PROJECT-scoped: `784814e7-...` (`DEVOPS - ACR`), `ca8fb3b0-...` (`Enterprise`); `b50e431e-...` is the wrong registry. Per-pipeline grants: `az devops invoke --area pipelinePermissions` with `--api-version 7.1-preview` (not `.1`). Graph blocked by Conditional Access (AADSTS53003): use `az rest` on ARM + `--assignee-object-id`. Check `az pipelines list` before creating a pipeline (duplicates race). An undefined `$(VAR)` stays literal. `Docker@2 buildAndPush` ignores `arguments` (no `--build-arg`): use `command: login` + plain `docker build/push`. Approval gates need environments + `deployment` jobs.

## Do-Not-Repeat

- **[2026-09-10]** `task.setvariable` is job-scoped: Build-stage variables arrive empty in other stages; re-derive from `$(Build.SourceBranch)`.
- **[2026-09-10]** Read actual app settings (`az webapp config appsettings list`) before claiming which DB IP/image a live app uses (itbudget = `.104`; cmms pulls `:latest`).
- **[2026-09-10]** A missing tool reads like a failing service (`ss` absent, budget uses `netstat`): verify the tool exists first.
- **[2026-08-28]** Check an SDK can talk to a service before documenting it (MinIO SDK vs Blob); read `init()` before documenting what a config value does.
- **[2026-08-28]** System-assigned identity creates a cycle in tofu; use user-assigned. Re-grep after `tofu fmt`, re-run `tofu validate` after bulk edits.
- **[2026-08-28]** Run `git fetch upstream --tags` before reasoning about upstream position; check sibling project names (`../budget`, not `../budgets`).

## Decisions

- **`.idea/` stays tracked** (zero upstream churn; carries JDK 17 + Lombok setup).
- **Secrets are seeded into Key Vault by hand; no tool reads them** (app settings hold unversioned `@Microsoft.KeyVault(...)` references).
- **Storage account stays publicly reachable, DB private** (browsers fetch SAS URLs directly). Open (2026-09-11): `stgcaneastcmms` has public access disabled, which breaks SAS downloads.
- **[2026-09-10] Prod DB `atlas`, user `atlas`, URL `https://cmms.enerkem.com`** (baked into the SPA at build; must be settled before the first image build).
- **[2026-09-11] Hand-built infra is reality;** `.azure/env/prod.env` is the live source for deployment settings, `infra/` is reference-only.
