# Enerkem plan — upstream v1.9.0, Azure Blob isolation, upstream PR

Owner's sequencing (2026-10-19): **merge v1.9.0 first and test it; then isolate the
Azure Blob implementation cleanly; then contribute it upstream.** Each step below
is a prompt to paste into a fresh Claude Code session in `C:\data\src\cmms`. Run
them in order; each one ends by updating `DEVELOPMENT-STATUS.md` so the next
session can see where the previous one stopped.

Facts gathered 2026-10-19 that the prompts rely on:

| item | value |
|---|---|
| Our base | `enerkem` merged up to upstream **v1.8.0**; `UPSTREAM_VERSION=1.8.0`; production runs `release/1.8.0-enerkem.2` |
| Target | upstream **v1.9.0** = `fc27abfd` (2026-09-22), **402 commits**; `upstream/main` is 25 past it — never merge `upstream/main` |
| Big moves in v1.9.0 | Spring Boot **3.2.3 → 3.5.16** (Java 17 kept); `frontend/package.json` **removes axios, firebase, jsonwebtoken** (64k-line lockfile churn); `UserService` ±336 lines; `StorageService` gains `uploadAt(byte[], String, String)` and `exists(String)`; signed URLs cached via `CacheService` |
| Hot spots touched | `WebSecurityConfig` (19), `OAuth2ClientRegistrationConfig` (10), `OAuth2AuthenticationSuccessHandler` (11), `EmailService2` (4), `api/Dockerfile` (12), `application.yml` (60), `docker-compose.yml` (27), `en.ts` (23), `api/pom.xml` (90) |
| Database | 8 new changesets (asset/location indexes, user session invalidation, refresh token, API-key lifecycle, optimistic-locking `version` columns, `UPDATE part SET version = 0`, user language). **No new PostgreSQL extensions** → no server prerequisite |
| Upstream deleted files we modified | none |
| Azure Blob footprint (ours) | commit `b90a0751`: `AzureBlobService.java` (new), `StorageType` `+AZURE`, `StorageServiceFactory` `+case`, `application.yml` `storage.azure.*`, `api/pom.xml` two deps. Upstream still has no Azure backend (`StorageType = GCP, MINIO`) |
| Upstream contribution rules | `api/CONTRIBUTING.md`: fork → change → PR, claim an issue first. **No CLA.** Project is dual-licensed (AGPLv3 + commercial) |

---

## Which model runs which prompt

Decided 2026-10-19 so each step runs on the cheapest model that can do it
without redoing work. Switch with `/model` before pasting the prompt.

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

---

## Governing principle — identical bytes (owner, 2026-10-19)

> "Our PR is actually part of our code, so when it becomes part of the upstream
> code, it will update our own code with no changes."

So the Azure Blob files on `enerkem` **are** the contribution, byte for byte:

1. The feature is brought to upstream quality **on `enerkem` first** (Prompt 3):
   neutral wording, no Enerkem-specific comments or defaults, their test and
   doc conventions. It keeps running in production from that same code.
2. The PR branch (Prompt 4) **copies those files verbatim** from `enerkem` onto
   `upstream/main` — no rewrite, no "cleaned-up version". If `upstream/main`
   forces a change (an interface moved), the change is made on `enerkem` first
   and copied again.
3. Every change requested in review is applied on `enerkem` the same day and
   re-copied, so the two never diverge. `git diff upstream/<branch> enerkem --
   <azure files>` must be empty at all times while the PR is open.
4. When the upstream release containing it is merged (Prompt 5), those files
   merge as **no-ops**. From then on they are upstream's to maintain and are
   removed from CLAUDE.md's conflict hot spots.

Files under this rule: `api/src/main/java/com/grash/service/AzureBlobService.java`,
the Azure test classes, the `AZURE` lines in `StorageType` / `StorageServiceFactory`
/ `StorageServiceFactoryTest`, the `storage.azure.*` block in `application.yml`,
the Azure dependencies in `api/pom.xml`, `AZURE-setup.md`, and the Azure rows in
`README.MD`, `.env.example`, `docker-compose.yml`.

---

## Test prerequisites (all prompts)

- `mvn -DskipFrontend=true test` from `api/` with JDK 17 is the gate before any
  merge lands on `enerkem` and before any release tag. Baseline 2026-10-19:
  767 tests, 0 failures (2 Testcontainers errors explained below).
- Testcontainers (integration tests, future Azurite test) needs Docker reachable
  over **TCP**: Docker Desktop 29 rejects docker-java's named-pipe transport
  (DEVELOPMENT-STATUS §12.26). Enable *Expose daemon on tcp://localhost:2375
  without TLS* in Docker Desktop → Settings → General, then run tests with
  `DOCKER_HOST=tcp://localhost:2375`. Until then the two integration tests
  error out with "Could not find a valid Docker environment" — that is the
  environment, not the code.

---

## Prompt 0 — decisions before any code (owner, 10 minutes) — **Model: Sonnet 5**

> Read CLAUDE.md §1–2 and ENERKEM-PLAN.md. I am the repo owner. Record these
> decisions in DEVELOPMENT-STATUS.md as a new section and amend CLAUDE.md §1
> accordingly, then commit on `enerkem` (do not push):
>
> 1. Policy: the Azure Blob Storage backend (and only it) may be contributed to
>    Grashjs/cmms through a GitHub fork. SSO, licensing, packaging and every other
>    Enerkem change stay private. Rules 1 and 2 of §1 otherwise stand: never push
>    to the `upstream` remote, never open issues/PRs for anything else.
> 2. Licensing: contributions go out under AGPLv3 (upstream has no CLA). If the
>    maintainers ask for a CLA or a relicensing grant, stop and bring it to me.
> 3. The GitHub account/fork is **`jarjona-enk/cmms`** (fork of Grashjs/cmms, created
>    2026-10-18). Local remote `fork` = `git@github.com:jarjona-enk/cmms.git`, SSH key
>    `~/.ssh/jarjona-enk` (ed25519, `SHA256:J/wp8VkOW1/x4WGypYJgH5eFgo/JlzXpd9ibI0Sw+1A`),
>    selected by `~/.ssh/config` (`Host github.com`). Verified 2026-10-19: auth as
>    jarjona-enk, read and dry-run push OK. Commit author for the PR: **`Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>`**
>    (decided 2026-10-19). On the `contrib/*` branch every commit is made with
>    `git -c user.name="Juan F Arjona - Enerkem Inc" -c user.email=jarjona@enerkem.com commit ...`
>    so no other identity leaks in. For GitHub to attribute the commits to
>    `jarjona-enk`, `jarjona@enerkem.com` must be a verified e-mail on that account
>    (Settings -> Emails); otherwise they show as unlinked - harmless, but check once.
>
> Do not start the v1.9.0 merge in this session.

---

## Prompt 1 — merge upstream v1.9.0 into `enerkem` (expect ~half a day) — **Model: Opus 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md (START HERE, §12.18, §12.23) and
> ENERKEM-PLAN.md. Work only on branch `enerkem`; never commit on `main`; never
> push to `upstream`. Ask me before anything destructive. Follow CLAUDE.md §2
> exactly:
>
> 1. `git switch main && git pull` (main tracks upstream/main), `git fetch upstream --tags`,
>    then `git switch enerkem`. Confirm `.git/MERGE_HEAD` does not exist.
> 2. `git switch -c merge/upstream-v1.9.0 enerkem` and `git merge v1.9.0 --no-commit`.
>    The tag is `fc27abfd`. Do NOT merge `upstream/main`.
> 3. Resolve conflicts with these standing rules:
>    - **SSO** (`WebSecurityConfig`, `OAuth2ClientRegistrationConfig`,
>      `OAuth2AuthenticationSuccessHandler`): keep the `if (enableSso)` gate with
>      the commercial-licence check removed, our SPA and `/source-code/**` permits,
>      and the `OAUTH2_TENANT_ID` authority pinning; take everything else from
>      upstream. Role lookup stays upstream's typed API + our `orElseThrow`.
>    - **Mail** (`EmailService2`, `UserService`): keep our recipient logging,
>      the non-fatal admin notification and `@Transactional(NOT_SUPPORTED)`
>      (§12.23); take upstream's other changes.
>    - **frontend/package.json + package-lock.json**: do NOT hand-merge. Take
>      upstream's both files, then re-apply only pins we still need (check
>      DEVELOPMENT-STATUS §"Upgraded to latest within-major"), then
>      `npm ci` (never `npm install`) and `npm run build`. Our dep-refresh is disposable.
>    - **api/pom.xml**: keep our frontend-maven-plugin and resource-copy blocks and
>      the two Azure dependencies; take upstream's Spring Boot 3.5.16 and the rest.
>    - **api/Dockerfile**: keep ours entirely (noble runtime, sshd, startup.sh).
>    - **application.yml**: keep `storage.azure.*` and our SMTP parameters; take
>      upstream's new keys.
>    - `en.ts`, `.gitignore`, `docker-compose.yml`: union.
> 4. **`AzureBlobService` must implement the new `StorageService` methods**
>    `uploadAt(byte[] data, String filePath, String contentType)` and
>    `boolean exists(String filePath)`, and route `generateSignedUrl(File, …)`
>    through `CacheService.getCachedOrGenerateSignedUrl` like `GCPService` does.
>    Mirror `GCPService`'s semantics (empty data → 400, overwrite at exact path).
> 5. Spring Boot 3.5 migration: fix whatever no longer compiles (watch Thymeleaf
>    `spring5` → `spring6` imports, Spring Security 6.5 API changes, Hibernate 6.6
>    with the new `version` columns under `ddl-auto: validate`).
> 6. `echo 1.9.0 > UPSTREAM_VERSION` **inside the merge commit**. Commit the merge.
> 7. Build: `cd api && .\mvnw.cmd -f ..\pom.xml -DskipTests package` with JDK 17
>    (`C:\java\jdk-17`). If the Maven wrapper misbehaves use the wrapper's own
>    Maven under `~/.m2/wrapper/dists/`. If a build dies with no error, check for
>    another session running `taskkill //IM java.exe` (cerebrum).
> 8. Update DEVELOPMENT-STATUS.md (new §: what v1.9.0 brought, each conflict and
>    its resolution, SSO/mail changes verified byte-for-byte against `enerkem`),
>    CLAUDE.md "Current position", cerebrum, buglog. Commit on the merge branch.
>    Do NOT merge into `enerkem` yet — Prompt 2 tests first.

---

## Prompt 2 — test v1.9.0 locally, then land it (expect ~half a day) — **Model: Sonnet 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md (latest section, §12.18 for the recipe)
> and ENERKEM-PLAN.md. We are on `merge/upstream-v1.9.0` with a successful build.
> Test it the way 1.8.0 was tested, then land it:
>
> 1. Local prerequisites: JDK 17; Postgres 18 `atlas/atlas` on `localhost:5432/atlas`;
>    `docker start cmms-minio` (recreate from `dev.env` MinIO credentials if gone);
>    `docker start cmms-mailhog` (SMTP 1025, API 8025). Port 8080 must be free
>    (another project sometimes holds it — do not kill processes you did not start
>    without asking). Run the jar with `MAIL_RECIPIENTS=…`, `ENABLE_EMAIL_NOTIFICATIONS=true`,
>    `SMTP_HOST=localhost SMTP_PORT=1025 SMTP_AUTH=false SMTP_STARTTLS=false`,
>    `PUBLIC_API_URL=PUBLIC_FRONT_URL=http://localhost:8080`.
> 2. Matrix, each must pass: (a) **fresh install** — wipe `public` schema
>    (`pg_dump -Fc` first), start, all changesets run (expect 806 + 8 = 814);
>    (b) **upgrade** — `pg_restore` the 1.8.0 dump, start, exactly 8 new changesets,
>    `UPDATE part SET version = 0` succeeds; (c) API suite: signup → JWT, create
>    location/asset/work order with accented names (send JSON from files with
>    `--data-binary`, Git Bash mangles UTF-8 arguments), accent-insensitive search
>    both ways, `/source-code/download` 200; (d) **mail**: invite two users →
>    MailHog shows one mail `To:` each invitee, no CC; register one via
>    `users/invite(disableSendingEmail=true)` then `auth/signup` with role → 200 and
>    a mail `To: MAIL_RECIPIENTS`; repeat with `SMTP_PORT=1` → registration still
>    200, failure logged with recipients; (e) browser via Playwright: login,
>    Work Orders and Assets grids render; (f) `GET /oauth2/authorize/microsoft`
>    → 302 to `login.microsoftonline.com/<OAUTH2_TENANT_ID>/…` with
>    `redirect_uri=http://localhost:8080/oauth2/callback/microsoft`.
> 3. Verify the served bundle hash equals `frontend/build/index.html`'s (a stale
>    gitignored SPA copy under `api/src/main/resources/static/` once shadowed the
>    build — `git clean -fdX api/src/main/resources/static`, keep `source/`).
> 4. Then: `git switch enerkem && git merge --no-ff merge/upstream-v1.9.0`,
>    `git branch -d merge/upstream-v1.9.0`. Stop all local processes. Update
>    DEVELOPMENT-STATUS.md (test matrix with numbers), memory. Commit.
> 5. Tell me the exact commands to push and tag: `release/1.9.0-enerkem.1` (counter
>    resets after an upstream merge). I push and tag. Production checklist for
>    first start: no new extensions needed; the 8 changesets run on the live
>    `atlas` database; watch `/health-check` on the azurewebsites host; container
>    logging is still off on the app, so read `/home/cmms/atlas.log` over SSH if
>    anything fails.

---

## Prompt 3 — isolate the Azure Blob implementation (expect ~a day) — **Model: Sonnet 5**

> Read CLAUDE.md, DEVELOPMENT-STATUS.md and ENERKEM-PLAN.md. `enerkem` is at
> upstream v1.9.0 and `release/1.9.0-enerkem.1` is in production. Goal: make the
> Azure Blob Storage backend a cleanly separable, upstream-quality feature while
> keeping production unchanged in behaviour. Work on `enerkem` (or a short-lived
> branch merged back with `--no-ff`). Ask before anything destructive.
>
> 1. Audit: `git log -S AzureBlobService --oneline enerkem` and
>    `git diff v1.9.0..enerkem -- <storage files>` — list every line of the
>    feature and every line in the same files that is NOT the feature (SSO, mail,
>    packaging). The feature must become: `AzureBlobService.java` (new file),
>    `StorageType +AZURE`, `StorageServiceFactory +case AZURE` (+ field),
>    `application.yml storage.azure.*` block, `api/pom.xml` dependencies —
>    nothing else.
> 2. Bring it to upstream quality on `enerkem`:
>    - dependencies via `com.azure:azure-sdk-bom` (current stable), no duplicate
>      version properties;
>    - implements the full current `StorageService` (`upload` ×2, `download` ×2,
>      `generateSignedUrl` ×2 via `CacheService`, `uploadAt`, `exists`);
>    - Enerkem-specific comments and env names replaced by neutral wording;
>      keep both auth modes (account key, `DefaultAzureCredential`/managed identity)
>      and user-delegation SAS — that is the feature's value;
>    - `StorageServiceFactoryTest`: `getStorageService_azure_returnsAzureService`;
>    - **`AzureBlobServiceTest` (Mockito, no Docker):** mocked `BlobServiceClient`
>      / `BlobContainerClient` / `BlobClient`; cover `upload` (key generation,
>      content type), `download` (missing → 404), `uploadAt` (empty → 400,
>      overwrite), `exists`, `generateSignedUrl` in both auth modes and through
>      `CacheService`, and `checkIfConfigured`. Run first: `mvn -DskipFrontend=true test`
>      must stay at 0 failures (767 tests on 2026-10-19, see DEVELOPMENT-STATUS §12.26);
>    - an **Azurite** Testcontainers integration test
>      (`mcr.microsoft.com/azure-storage/azurite`): upload → exists → download →
>      signed URL → `uploadAt` overwrite → `exists` false for a missing path;
>    - docs in upstream's pattern: `AZURE-setup.md` (mirror `GCP-setup.md`: create
>      account + container; either an account key or a managed identity with
>      *Storage Blob Data Contributor* + *Storage Blob Delegator*; note that a
>      private-only account needs DNS that resolves to the private endpoint),
>      README env-table rows (`STORAGE_TYPE` → `gcp | minio | azure`,
>      `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`, `AZURE_STORAGE_ACCOUNT_KEY`,
>      `AZURE_STORAGE_ENDPOINT`), `.env.example` entries, `docker-compose.yml`
>      passthrough of the four variables.
> 3. Prove isolation: `git diff v1.9.0..enerkem -- <the files above>` must be the
>    entire feature and nothing else; `mvn test` green; local run with
>    `STORAGE_TYPE=minio` unchanged; Azurite test green.
> 4. Record in DEVELOPMENT-STATUS.md the exact file list and the diff size.
>    Commit. Tell me whether this needs a production release (it should not change
>    behaviour; if it does, say so and propose `release/1.9.0-enerkem.2`).

---

## Prompt 4 — prepare the upstream pull request (expect ~half a day + review time) — **Model: Sonnet 5**

> Read CLAUDE.md (§1 as amended by Prompt 0), DEVELOPMENT-STATUS.md and
> ENERKEM-PLAN.md. Prepare — do not open until I say so — the upstream PR for the
> Azure Blob Storage backend:
>
> 1. The remote `fork` (`git@github.com:jarjona-enk/cmms.git`, SSH) already exists. Never touch the
>    `upstream` remote's push URL (`DISABLED`); never push `enerkem` or `main`
>    anywhere but `origin`.
> 2. `git fetch upstream && git switch -c contrib/azure-blob-storage upstream/main`
>    (clean room: based on upstream's `main`, not on `enerkem`). Re-apply **only**
>    the isolated feature from Prompt 3 by **copying the files verbatim from
>    `enerkem`** (`git checkout enerkem -- <file>` per file; no cherry-pick of
>    Enerkem commits, no edits on this branch). If `upstream/main` has moved the storage interface again,
>    adapt **on `enerkem` first**, commit there, then copy again — the identical-bytes
>    rule above.
>    Commit as `Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>` (Prompt 0), one
>    commit: `feat(storage): add Azure Blob Storage backend (STORAGE_TYPE=azure)`.
> 3. Build and test against upstream's toolchain: `mvn -B verify` in `api/`
>    (their Spring Boot version), including the Azurite test. The diff must touch
>    only: `AzureBlobService.java`, `AzureBlobServiceIT` (or their naming),
>    `StorageServiceFactoryTest`, `StorageType`, `StorageServiceFactory`,
>    `application.yml`, `api/pom.xml`, `AZURE-setup.md`, `README.MD`,
>    `.env.example`, `docker-compose.yml`. Anything else is a leak — remove it.
> 4. Write the PR text into `ENERKEM-PLAN.md` → "PR text" section: title
>    `feat(storage): Azure Blob Storage backend (STORAGE_TYPE=azure)`; what it
>    adds, the two auth modes, SAS behaviour (same browser-direct model as GCP /
>    MinIO), the Azurite test, docs; note it has run in production at Enerkem since
>    2026-09 on Azure App Service with a managed identity. Also draft the GitHub
>    issue to open first ("feature request: Azure Blob Storage backend — I will
>    submit a PR"), as their CONTRIBUTING asks.
> 5. Push the branch to `fork` only when I confirm; I open the issue and the PR
>    myself. Record the issue/PR URLs in DEVELOPMENT-STATUS.md when they exist.

---

## Prompt 5 — after upstream merges it — **Model: Opus 5**

> Read CLAUDE.md and ENERKEM-PLAN.md. Upstream released a version containing the
> Azure Blob backend (tag `<vX.Y.Z>`). Merge that release into `enerkem` per
> CLAUDE.md §2, and verify during the merge that `AzureBlobService.java`, the Azure tests,
> `StorageType`, `StorageServiceFactory`, the `storage.azure.*` YAML block, the
> Azure dependencies and the Azure docs merge as **no-ops** (identical bytes). If
> any of them conflicts, the identical-bytes rule was broken somewhere — stop and
> report which side drifted before resolving.
> Re-run the Prompt 2 matrix plus a real upload/download against `stgcaneastcmms`
> (managed identity path) before tagging. Update CLAUDE.md "Known conflict hot
> spots" to remove the Azure files from our conflict surface.

---

## PR text

*(filled in by Prompt 4)*
