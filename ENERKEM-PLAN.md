# Enerkem plan — upstream v1.9.0, Azure Blob isolation, upstream PR

Owner's sequencing (2026-10-19): **merge v1.9.0 and test it locally; isolate the
Azure Blob implementation; contribute it upstream.** Each step below is a prompt
to paste into a fresh Claude Code session in `C:\data\src\cmms`, on the model
named in its heading (`/model` first). Run them in order. Every prompt ends by
updating `DEVELOPMENT-STATUS.md` and committing on `enerkem`, so the next
session can see where the previous one stopped. All decisions needed to run
them unattended were taken by the owner on 2026-10-19 and are written in.

## Directive for this whole exercise — LOCAL ONLY

> "All the work must be done locally. We don't touch production ever without me
> tagging and pushing."

- **No session touches production or any Azure resource** — not the web app,
  not its settings or logging, not the production database (no reads either),
  not the storage account, not the pipeline. No `az` commands. If a prompt seems
  to need production, stop and report instead.
- **No session pushes to `origin` or creates tags.** Sessions commit on
  `enerkem` locally and end with the exact `git push` / `git tag` commands for
  the owner. The owner deploys by tagging; the owner verifies production.
- The only remote a session may push to is **`fork`** (the owner's GitHub fork),
  only `contrib/*` branches, only in Prompt 4.
- Never push to `upstream` (push URL is `DISABLED`); never commit on `main`.
- Local resources a session MAY use freely: the local Postgres (`atlas`
  database — wipe and restore at will after dumping), Docker Desktop and local
  containers (`cmms-minio`, `cmms-mailhog`, Azurite), ports 8080/8085/1025/
  8025/9000/10000, the scratchpad. Never kill a process the session did not
  start (another project's java often sits on 8080).

## Which model runs which prompt

| prompt | model | why |
|---|---|---|
| 0 | **Sonnet 5** | edits two documents from a decision list; no code, no judgement calls |
| 1 | **Opus 5** | 402-commit upstream merge with Spring Boot 3.2→3.5, SSO/mail conflict resolution and an interface change in AzureBlobService — the one step where a wrong resolution silently breaks production |
| 2 | **Sonnet 5** | executes a fixed test matrix and lands the branch; escalate to Opus 5 only if a failure has no obvious cause |
| 3 | **Sonnet 5** | tests, docs and an isolation audit against an exact file list; Mockito/Azurite tests are well-defined work |
| 4 | **Sonnet 5** | verbatim file copy onto upstream/main, build on their toolchain, PR prose |
| 5 | **Opus 5** | an upstream release merge, like Prompt 1, plus proving the no-op |

Rule of thumb: upstream merges and anything that resolves conflicts in SSO,
mail or storage code → **Opus 5**. Executing a defined matrix, writing tests
against a spec, copying files, prose → **Sonnet 5**. If a Sonnet session hits a
failure it cannot explain in two attempts, stop and rerun that prompt on Opus 5
rather than iterating.

## Decisions taken (2026-10-19) — the prompts assume these

| topic | decision |
|---|---|
| Frontend dependencies in the v1.9.0 merge | **Take upstream's `package.json` and `package-lock.json` as-is.** Our August within-major refresh is dropped; it was housekeeping. `npm ci`, never `npm install`. |
| Conflicts not covered by the standing rules | **Prefer upstream, log the choice in DEVELOPMENT-STATUS, continue.** Stop only if the conflict touches SSO, mail, AGPL/source-code, or Enerkem packaging (Dockerfile, startup.sh, pipeline, `.azure/`). |
| Test database | **Local only**: fresh install from an empty `public` schema, and an upgrade from a `pg_dump` of the local 1.8.0 database. No production data. |
| Integration tests | Owner enables Docker Desktop → Settings → General → *Expose daemon on tcp://localhost:2375 without TLS*. Sessions run tests with `DOCKER_HOST=tcp://localhost:2375`. If `curl http://localhost:2375/_ping` is not `200`, stop and ask — do not try pipe variants (all tried; Docker Desktop 29 rejects docker-java's named-pipe transport). |
| SSO check in Prompt 2 | **Port 8080 required** (the registered local redirect URI). If 8080 is busy, stop and ask; never kill the other process. |
| Pushes and tags | **Owner only.** Sessions hand over commands. |
| Upstream PR | Session pushes `contrib/azure-blob-storage` to `fork`; **owner opens the issue and the PR in the browser** (no `gh`). |
| GitHub identity | Fork `jarjona-enk/cmms`; remote `fork` = `git@github.com:jarjona-enk/cmms.git`; SSH key `~/.ssh/jarjona-enk` via `~/.ssh/config`. PR commits authored **`Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>`** (set per command with `git -c user.name=... -c user.email=...` on `contrib/*` only). `jarjona@enerkem.com` must be a verified e-mail on the `jarjona-enk` account for attribution. |
| Licensing | Contributions go out under AGPLv3; upstream has no CLA. If maintainers ask for a CLA or relicensing grant, stop and bring it to the owner. |

## Facts the prompts rely on (gathered 2026-10-19)

| item | value |
|---|---|
| Our base | `enerkem` merged up to upstream **v1.8.0**; `UPSTREAM_VERSION=1.8.0`; production runs `release/1.8.0-enerkem.2` |
| Target | upstream **v1.9.0** = `fc27abfd` (2026-09-22), **402 commits**; `upstream/main` is 25 past it — never merge `upstream/main` |
| Big moves in v1.9.0 | Spring Boot **3.2.3 → 3.5.16** (Java 17 kept); `frontend/package.json` **removes axios, firebase, jsonwebtoken** (64k-line lockfile churn); `UserService` ±336 lines; `StorageService` gains `uploadAt(byte[], String, String)` and `exists(String)`; signed URLs cached via `CacheService.getCachedOrGenerateSignedUrl` |
| Hot spots touched | `WebSecurityConfig` (19), `OAuth2ClientRegistrationConfig` (10), `OAuth2AuthenticationSuccessHandler` (11), `EmailService2` (4), `api/Dockerfile` (12), `application.yml` (60), `docker-compose.yml` (27), `en.ts` (23), `api/pom.xml` (90) |
| Database | 8 new changesets (asset/location indexes, user session invalidation, refresh token, API-key lifecycle, optimistic-locking `version` columns, `UPDATE part SET version = 0`, user language). **No new PostgreSQL extensions.** Local baseline: 806 changesets, `unaccent` installed → expect **814** |
| Upstream deleted files we modified | none |
| Azure Blob footprint (ours) | commit `b90a0751`: `AzureBlobService.java` (new), `StorageType` `+AZURE`, `StorageServiceFactory` `+case`, `application.yml` `storage.azure.*`, `api/pom.xml` two deps. Upstream has no Azure backend (`StorageType = GCP, MINIO`) |
| Test suite | `mvn -DskipFrontend=true test` from `api/`, JDK 17: **767 tests, 0 failures** on 2026-10-19 (2 Testcontainers errors = Docker transport, see Decisions). No Azure Blob tests exist yet. Run online the first time (Surefire's JUnit provider is not cached) |
| Local toolchain | JDK 17 at `C:\java\jdk-17`; Maven wrapper from `api/` (`.\mvnw.cmd -f ..\pom.xml`); if the wrapper misbehaves, `C:\Users\JArjona\.m2\wrapper\dists\apache-maven-3.8.6-bin\*\apache-maven-3.8.6\bin\mvn.cmd`; Postgres 18 `atlas/atlas` on `localhost:5432/atlas`, credentials in gitignored `dev.env`; `psql`/`pg_dump`/`pg_restore` in `C:\Program Files\PostgreSQL\18\bin`; the local `atlas` role cannot `CREATE DATABASE` — wipe and recreate the `public` schema instead |
| Local containers | Docker Desktop 29.9.1. The 2026-10-19 update **removed all containers**; recreate as needed (read `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` from `dev.env`): `docker run -d --name cmms-minio -p 9000:9000 -p 9001:9001 -e MINIO_ROOT_USER=$MINIO_ACCESS_KEY -e MINIO_ROOT_PASSWORD=$MINIO_SECRET_KEY quay.io/minio/minio server /data --console-address ":9001"` and `docker run -d --name cmms-mailhog -p 1025:1025 -p 8025:8025 mailhog/mailhog`. Redirect `docker run` output to a file — never pipe it into `head`. Azurite image `mcr.microsoft.com/azure-storage/azurite` is cached |
| Local run | `java -jar api/target/app.jar --server.port=PORT` with `dev.env` exported plus `MAIL_RECIPIENTS=cmms-admins@enerkem.test ENABLE_EMAIL_NOTIFICATIONS=true INVITATION_VIA_EMAIL=true SMTP_HOST=localhost SMTP_PORT=1025 SMTP_AUTH=false SMTP_STARTTLS=false PUBLIC_API_URL=http://localhost:PORT PUBLIC_FRONT_URL=http://localhost:PORT`. The SPA's API URL is baked at build time: build with `-Dfrontend.api.url=http://localhost:PORT`. Startup ≈ 30–50 s; wait for `Started ApiApplication` |
| Known traps | Git Bash converts UTF-8 command-line args through the ANSI codepage — send JSON bodies from files with `curl --data-binary @file` (write them with `printf '\xNN'`). `-DskipFrontend=true` also skips copying `frontend/build` into the jar. Heredoc-fed Python scripts break on quoting — write scripts to the scratchpad with the Write tool and run them by path. A `.wolf/` directory holds OpenWolf bookkeeping (ours, commit it). Another Claude session (cybermap) may run `taskkill //IM java.exe`; a java process or Maven build dying with no log is that, not a bug. C: drive is at 99 % (12 GB free); stop and ask if free space < 10 GB |
| Durable dumps | `C:\data\src\cmms\atlas_backups\` (gitignored and docker-ignored; create it if absent) — never the session scratchpad, which does not survive a session |

---

## Prompt 0 — decisions before any code (owner, 10 minutes) — **Model: Sonnet 5**

> Read CLAUDE.md §1–2 and ENERKEM-PLAN.md (Directive, Decisions). Work on
> branch `enerkem`; never commit on `main`; do not push. Make these edits and
> commit them on `enerkem` with message `docs: policy - local-only development;
> Azure Blob backend may be contributed upstream`:
>
> 1. CLAUDE.md §1: add rule 6 — *"All development and testing is local. No
>    session touches production or Azure resources, pushes to `origin`, or
>    creates tags; the owner does that. The only remote a session may push to
>    is `fork` (`contrib/*` branches, Prompt 4 of ENERKEM-PLAN.md)."*
> 2. CLAUDE.md §1: amend the opening sentence *"nothing here is ever contributed
>    upstream"* to: *"nothing here is contributed upstream, with one sanctioned
>    exception: the Azure Blob Storage backend, via the owner's fork
>    `jarjona-enk/cmms` and under AGPLv3 (see ENERKEM-PLAN.md). SSO, licensing,
>    packaging and every other Enerkem change stay private."* Keep rules 1 and 2
>    (never push to `upstream`, never open issues/PRs for anything else).
> 3. CLAUDE.md §1 remotes table: add the `fork` row
>    (`git@github.com:jarjona-enk/cmms.git`, "owner's GitHub fork; `contrib/*`
>    only").
> 4. DEVELOPMENT-STATUS.md: new section "12.27 Policy decisions for the v1.9.0 /
>    Azure contribution work" copying the Directive and Decisions tables from
>    ENERKEM-PLAN.md verbatim.
> 5. `mkdir atlas_backups` if it does not exist (it is already gitignored; add
>    nothing inside).
>
> Do not start the v1.9.0 merge. End by printing `git log --oneline -3` and the
> push command for the owner: `git push origin enerkem`.

---

## Prompt 1 — merge upstream v1.9.0 into `enerkem` — **Model: Opus 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md (START HERE, §12.18, §12.23, §12.27)
> and ENERKEM-PLAN.md (Directive, Decisions, Facts). Local only: no `az`, no
> production, no pushes, no tags. Work on a merge branch; never commit on
> `main`. Ask only for things the Decisions table does not settle.
>
> **Pre-flight (stop and report if any fails):** `git branch --show-current`
> is `enerkem` and the tree is clean (`.wolf/` and `.idea/` changes may be
> committed or ignored); `.git/MERGE_HEAD` does not exist; `git fetch upstream
> --tags` succeeds; `git rev-parse v1.9.0` is `fc27abfd…`; free space on C:
> ≥ 10 GB; JDK 17 at `C:\java\jdk-17`.
>
> **Merge:**
> 1. `git switch main && git pull` (main tracks upstream/main), then
>    `git switch enerkem`.
> 2. `git switch -c merge/upstream-v1.9.0 enerkem` and
>    `git merge v1.9.0 --no-commit`. Do NOT merge `upstream/main`.
> 3. Resolve conflicts with these standing rules; everything not covered →
>    prefer upstream and log the choice:
>    - **SSO** (`WebSecurityConfig`, `OAuth2ClientRegistrationConfig`,
>      `OAuth2AuthenticationSuccessHandler`): keep the `if (enableSso)` gate with
>      the commercial-licence check removed, our SPA and `/source-code/**`
>      permits, and the `OAUTH2_TENANT_ID` authority pinning; take everything else
>      from upstream. The Administrator-role lookup stays upstream's typed API +
>      our `.orElseThrow(CustomException)`.
>    - **Mail** (`EmailService2`, `UserService`): keep our recipient logging,
>      the `catch (Exception)` around the admin notification, the `invite()` log
>      line and `@Transactional(Transactional.TxType.NOT_SUPPORTED)` on
>      `EmailService2` (§12.23); take upstream's other changes.
>    - **Frontend `package.json` + `package-lock.json`**: take upstream's both
>      files unchanged (`git checkout v1.9.0 -- frontend/package.json
>      frontend/package-lock.json`). Do not re-apply our pins.
>    - **`api/pom.xml`**: keep our frontend-maven-plugin and resource-copy
>      blocks and the two Azure dependencies; take upstream's Spring Boot
>      3.5.16 and everything else.
>    - **`api/Dockerfile`, `api/container/*`, `azure-pipelines.yml`,
>      `.azure/**`, `scripts/**`, `infra/**`, and our root documents
>      (`DEVELOPMENT-STATUS.md`, `REQUIREMENTS.md`, `ENERKEM-PLAN.md`,
>      `CLAUDE.md`, `UPSTREAM_VERSION`)**: keep ours entirely.
>    - **`application.yml`**: keep `storage.azure.*` and our SMTP parameters
>      (`properties.mail.smtp.auth/starttls.enable` parameterised); take
>      upstream's new keys.
>    - `en.ts`, `.gitignore`, `docker-compose.yml`, `README.MD`: union.
> 4. **`AzureBlobService` must compile against the new `StorageService`:**
>    implement `uploadAt(byte[] data, String filePath, String contentType)`
>    (empty data → `CustomException` 400; overwrite at the exact path, set
>    content type) and `boolean exists(String filePath)`; inject `CacheService`
>    and route `generateSignedUrl(File, long)` through
>    `cacheService.getCachedOrGenerateSignedUrl` exactly as `GCPService` does.
>    Mirror `GCPService`'s error semantics.
> 5. Spring Boot 3.5 fallout: fix whatever no longer compiles (Thymeleaf
>    `spring5` → `spring6` imports, Spring Security 6.5 API changes, Hibernate
>    6.6 with the new `version` columns under `ddl-auto: validate`). Minimal
>    changes; no refactors.
> 6. `echo 1.9.0 > UPSTREAM_VERSION` **inside the merge commit**. Commit the
>    merge with a message listing every conflict and its resolution.
>
> **Build and unit tests (required before this prompt ends):**
> 7. `cd api && .\mvnw.cmd -f ..\pom.xml -DskipTests package` with JDK 17 — full
>    build, frontend included (10–15 min). Then `.\mvnw.cmd -f ..\pom.xml
>    -DskipFrontend=true test` with `DOCKER_HOST=tcp://localhost:2375` (check
>    `curl http://localhost:2375/_ping` is 200 first; if not, run the unit tests
>    only with `-Dtest='!*IntegrationTest'` and say so). Target: 0 failures.
>    Fix test compilation/assertion fallout from the merge; do not delete tests.
> 8. Verify byte-for-byte that our protected changes survived: `git diff enerkem
>    merge/upstream-v1.9.0 -- <SSO files, EmailService2, UserService>` shows
>    only upstream's additions, never a removal of ours.
>
> **Record and stop:** update DEVELOPMENT-STATUS.md (new section: what v1.9.0
> brought, each conflict and its resolution, every "preferred upstream" choice,
> test numbers), CLAUDE.md "Current position" (merged to v1.9.0, next tag), the
> cerebrum (new learnings) and the buglog (anything fixed). Commit on
> `merge/upstream-v1.9.0`. Do NOT merge into `enerkem` — Prompt 2 tests first.
> End with `git log --oneline -5`.

---

## Prompt 2 — test v1.9.0 locally, land it, hand over the tag — **Model: Sonnet 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md (the Prompt 1 section, §12.18 for the
> recipe, §12.23) and ENERKEM-PLAN.md (Directive, Decisions, Facts). Local
> only: no `az`, no production, no pushes, no tags. We are on
> `merge/upstream-v1.9.0` with a green build. Stop and ask on any check that
> fails twice without an obvious cause (then the owner reruns on Opus 5).
>
> **Prerequisites:** Docker Desktop running and `curl http://localhost:2375/_ping`
> = 200 (else stop); containers `cmms-minio` and `cmms-mailhog` running
> (recreate with the commands in Facts → Local containers if missing); **port
> 8080 free** — if busy, stop and ask, never kill it; local Postgres up.
>
> **Database baseline:** `pg_dump -Fc` the local `atlas` database (1.8.0
> schema, 806 changesets) to `atlas_backups\atlas-1.8.0-<yyyymmdd>.dump` BEFORE
> anything else.
>
> **Build for 8080:** the jar from Prompt 1 may be baked for another URL —
> rebuild once: `cd api && .\mvnw.cmd -f ..\pom.xml -DskipTests
> -Dfrontend.api.url=http://localhost:8080 clean package`. Verify the bundle hash
> in `api/target/classes/static/index.html` equals `frontend/build/index.html`.
>
> **Run (all on 8080, env as in Facts → Local run):**
> 1. **Fresh install:** drop and recreate the local `public` schema (`drop schema
>    public cascade; create schema public;` as `atlas`), start the jar, expect
>    Liquibase `Run: 814, Previously run: 0`, `Started ApiApplication`,
>    `/health-check` 200, `/` 200 with `id="root"`.
> 2. **API suite** (JSON from files, `--data-binary`): signup → JWT; `/auth/me`
>    role Administrator; create location/asset/work order with accented names;
>    `POST /assets/search` with `{"field":"name","operation":"cn","value":"generatrice"}`
>    finds `Génératrice` and with `GÉNÉ` too; work-order search; `POST /parts/search`
>    200; `/api-docs.html` 200; `/source-code/download` 200 ≈ 93 MB; `/app/work-orders`
>    200.
> 3. **Mail (MailHog API `http://localhost:8025/api/v2/messages`):** clear
>    MailHog; `POST /users/invite` two addresses with `disableSendingEmail:false`
>    → exactly 2 mails, each `To:` one invitee, no CC; resend one → 1 more mail;
>    then `POST /users/invite` that address with `disableSendingEmail:true` and
>    `POST /auth/signup` with `role:{id}` → HTTP 200 with a token, user row
>    created, 1 mail `To: cmms-admins@enerkem.test` "New … registration".
>    Restart with `SMTP_PORT=1`: repeat the registration → still **200** and an
>    `ERROR … Admin notification … could not be sent to cmms-admins@…` log line.
> 4. **Browser (Playwright MCP):** login at `/account/login` with a user created
>    above, Work Orders and Assets grids show the created rows; console has no
>    errors other than the known `runtime-env.js` 500.
> 5. **SSO wiring:** `GET /oauth2/authorize/microsoft` → 302 to
>    `login.microsoftonline.com/<OAUTH2_TENANT_ID from dev.env>/oauth2/v2.0/authorize`
>    with `client_id=<OAUTH2_CLIENT_ID>` and
>    `redirect_uri=http://localhost:8080/oauth2/callback/microsoft`. Then leave
>    the instance running with `ENABLE_SSO=true` and tell the owner it is ready
>    for the manual SSO round-trip; wait for the owner's confirmation before step 6.
> 6. **Upgrade path:** stop the jar; drop/recreate `public`; `pg_restore --no-owner
>    --no-privileges` the 1.8.0 dump; start → expect `Run: 8, Previously run: 806`
>    and the API suite green again.
>
> **Land:** stop all local jars. `git switch enerkem && git merge --no-ff
> merge/upstream-v1.9.0 -m "Merge branch merge/upstream-v1.9.0"` and
> `git branch -d merge/upstream-v1.9.0`. Update DEVELOPMENT-STATUS.md (matrix
> with the numbers, SSO round-trip result as the owner reported it), CLAUDE.md
> "Current position", memory. Commit on `enerkem`.
>
> **Hand over (do not run):** print for the owner
> `git push origin enerkem`, `git tag release/1.9.0-enerkem.1`,
> `git push origin release/1.9.0-enerkem.1` (counter resets after an upstream
> merge), plus the production notes: no new extensions needed; 8 changesets run
> at first start; the owner verifies `/health-check` on the azurewebsites host.

---

## Prompt 3 — isolate the Azure Blob implementation — **Model: Sonnet 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md and ENERKEM-PLAN.md (Directive,
> Governing principle, Decisions, Facts). `enerkem` is at upstream v1.9.0.
> Local only; no pushes. Goal: make the Azure Blob Storage backend a cleanly
> separable, upstream-quality feature **on `enerkem` itself**, with no change
> in behaviour for production. Work on `enerkem` directly (small commits).
>
> 1. **Audit.** `git log -S AzureBlobService --oneline enerkem` and
>    `git diff v1.9.0..enerkem -- api/src/main/java/com/grash/service/AzureBlobService.java
>    api/src/main/java/com/grash/model/enums/StorageType.java
>    api/src/main/java/com/grash/factory/StorageServiceFactory.java
>    api/src/main/resources/application.yml api/pom.xml`. List every Azure line,
>    and every non-Azure Enerkem line in the shared files (SSO, mail, packaging)
>    so the two are never confused.
> 2. **Upstream quality, in place:**
>    - dependencies via `com.azure:azure-sdk-bom` in `<dependencyManagement>`
>      (latest stable from Maven Central; check with `curl
>      "https://search.maven.org/solrsearch/select?q=g:com.azure+AND+a:azure-sdk-bom&rows=1&wt=json"`),
>      versionless `azure-storage-blob` and `azure-identity`; remove the two
>      `azure.*.version` properties;
>    - `AzureBlobService` implements the full current `StorageService` (`upload`
>      ×2, `download` ×2, `generateSignedUrl` ×2 via `CacheService`, `uploadAt`,
>      `exists`) with `GCPService` as the reference for semantics and error
>      codes; keep both auth modes (account key; `DefaultAzureCredential` /
>      managed identity with user-delegation SAS) — that is the feature's value;
>    - wording: no "Enerkem", no internal host names or ticket references in
>      comments or messages; env names stay `AZURE_STORAGE_ACCOUNT`,
>      `AZURE_STORAGE_ACCOUNT_KEY`, `AZURE_STORAGE_CONTAINER`,
>      `AZURE_STORAGE_ENDPOINT` (production depends on them);
>    - `StorageServiceFactoryTest`: `getStorageService_azure_returnsAzureService`
>      in the existing style (`@Mock AzureBlobService`, `ReflectionTestUtils`);
>    - **`AzureBlobServiceTest` (Mockito, no Docker)**: mock `BlobServiceClient`
>      / `BlobContainerClient` / `BlobClient`; cover `upload` (unique path,
>      content type), `download` (missing blob → `CustomException` 404),
>      `uploadAt` (empty → 400; overwrite), `exists` true/false,
>      `generateSignedUrl` in shared-key mode and in user-delegation mode and
>      that the `File` overload goes through `CacheService`, and the
>      not-configured guard;
>    - **Azurite integration test** (`AzureBlobServiceIT`, Testcontainers
>      `GenericContainer("mcr.microsoft.com/azure-storage/azurite")` exposing
>      10000, shared-key mode with Azurite's well-known dev account): real
>      upload → exists → download bytes equal → signed URL fetchable → `uploadAt`
>      overwrite → `exists` false for a missing path. Skip cleanly when Docker is
>      unavailable (`@Testcontainers(disabledWithoutDocker = true)`);
>    - docs in upstream's pattern: `AZURE-setup.md` at the repo root mirroring
>      `GCP-setup.md` (create storage account + container; either an account key
>      or a managed identity with *Storage Blob Data Contributor* + *Storage Blob
>      Delegator*; note that browsers download via SAS URL on the blob host, so
>      the account must be reachable from users' browsers — a private-only
>      account needs DNS that resolves to its private endpoint); README env-table
>      rows (`STORAGE_TYPE` → `gcp | minio | azure`, the four `AZURE_*` variables)
>      and a link to `AZURE-setup.md` next to the GCP one; `.env.example` entries;
>      `docker-compose.yml` passthrough of the four variables.
> 3. **Prove it.** `mvn -DskipFrontend=true test` (with `DOCKER_HOST=tcp://localhost:2375`)
>    is green including the new tests; `git diff v1.9.0..enerkem -- <the Azure
>    files and the Azure hunks of the shared files>` contains the whole feature
>    and nothing else; a local run with `STORAGE_TYPE=minio` is unchanged.
> 4. Record in DEVELOPMENT-STATUS.md the exact file list and hunk list that
>    constitutes the contribution (this list is what Prompt 4 copies). Commit on
>    `enerkem`. Tell the owner whether any behaviour changed; if it did, propose
>    `release/1.9.0-enerkem.2` and print the push/tag commands (do not run them).

---

## Prompt 4 — prepare the upstream pull request — **Model: Sonnet 5**

> Read CLAUDE.md (§1 as amended by Prompt 0), DEVELOPMENT-STATUS.md (the
> Prompt 3 section with the contribution file list) and ENERKEM-PLAN.md
> (Directive, Governing principle, Decisions). Prepare the upstream PR branch;
> push it to `fork` only; the owner opens the issue and the PR.
>
> 1. Remotes: `fork` = `git@github.com:jarjona-enk/cmms.git` (SSH, key
>    `~/.ssh/jarjona-enk`) exists. Never touch `upstream`'s push URL
>    (`DISABLED`); never push `enerkem` or `main` anywhere (only the owner does
>    that, to `origin`).
> 2. `git fetch upstream && git switch -c contrib/azure-blob-storage upstream/main`
>    — clean room on upstream's `main`, not on `enerkem`.
> 3. Re-apply **only** the contribution by **copying verbatim from `enerkem`**:
>    `git checkout enerkem -- <each Azure file>` for the Azure-only files, and
>    for shared files (`StorageType`, `StorageServiceFactory`,
>    `StorageServiceFactoryTest`, `application.yml`, `api/pom.xml`, `README.MD`,
>    `.env.example`, `docker-compose.yml`) apply exactly the Azure hunks from the
>    Prompt 3 list — no other Enerkem line may appear. If `upstream/main` has
>    moved the storage interface since v1.9.0, adapt **on `enerkem` first**,
>    commit there, then copy again (identical-bytes rule).
> 4. Build and test with upstream's toolchain: `cd api && mvn -B verify`
>    (`DOCKER_HOST=tcp://localhost:2375`), including `AzureBlobServiceIT`.
>    `git diff upstream/main --stat` must list only the contribution files.
>    Anything else is a leak — remove it.
> 5. One commit, authored `git -c user.name="Juan F Arjona - Enerkem Inc"
>    -c user.email=jarjona@enerkem.com commit -m "feat(storage): add Azure Blob
>    Storage backend (STORAGE_TYPE=azure)"` with a body describing the two auth
>    modes, SAS behaviour (same browser-direct model as GCP/MinIO), the Azurite
>    test and the docs.
> 6. `git push fork contrib/azure-blob-storage`.
> 7. Write into the "PR text" section at the end of ENERKEM-PLAN.md: (a) the
>    GitHub **issue** text to open first ("Feature request: Azure Blob Storage
>    backend — I will submit a PR"), (b) the **PR** title and description
>    (what it adds, configuration, how it was tested, that it runs in production
>    at Enerkem since 2026-09 on Azure App Service with a managed identity),
>    (c) the exact URL for the owner to open the PR:
>    `https://github.com/Grashjs/cmms/compare/main...jarjona-enk:cmms:contrib/azure-blob-storage`.
>    Commit that on `enerkem`. End by printing the two texts and the URL.
>
> While the PR is open, the rule is: every review change is made on `enerkem`
> first and re-copied to `contrib/azure-blob-storage`; `git diff enerkem
> contrib/azure-blob-storage -- <contribution files>` must stay empty.

---

## Prompt 5 — after upstream merges it — **Model: Opus 5**

> Read CLAUDE.md and ENERKEM-PLAN.md. Upstream released a version containing
> the Azure Blob backend (tag `<vX.Y.Z>` — the owner names it). Merge that
> release into `enerkem` per CLAUDE.md §2 and this plan's Prompt 1 rules
> (local only, no pushes, no tags, owner hands over the tag). During the merge
> verify that `AzureBlobService.java`, the Azure tests, `StorageType`,
> `StorageServiceFactory`, the `storage.azure.*` YAML block, the Azure
> dependencies and the Azure docs merge as **no-ops** (identical bytes). If any
> of them conflicts, the identical-bytes rule was broken somewhere — stop and
> report which side drifted before resolving. Re-run the Prompt 2 matrix.
> Update CLAUDE.md "Known conflict hot spots" to remove the Azure files from our
> conflict surface. End with the push/tag commands for the owner.

---

## Governing principle — identical bytes (owner, 2026-10-19)

> "Our PR is actually part of our code, so when it becomes part of the upstream
> code, it will update our own code with no changes."

The Azure Blob files on `enerkem` **are** the contribution, byte for byte: the
feature is brought to upstream quality on `enerkem` first (Prompt 3); the PR
branch copies those files verbatim (Prompt 4); every review change is applied
on `enerkem` the same day and re-copied; the upstream merge that brings it back
is a no-op for those files (Prompt 5). Files under this rule:
`api/src/main/java/com/grash/service/AzureBlobService.java`, the Azure test
classes, the `AZURE` lines in `StorageType` / `StorageServiceFactory` /
`StorageServiceFactoryTest`, the `storage.azure.*` block in `application.yml`,
the Azure dependencies in `api/pom.xml`, `AZURE-setup.md`, and the Azure rows in
`README.MD`, `.env.example`, `docker-compose.yml`.

---

## PR text

*(filled in by Prompt 4)*
