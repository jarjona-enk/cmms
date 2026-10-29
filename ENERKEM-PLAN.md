# Enerkem plan — v1.9.0, Azure Blob contribution, merge back, retire the fork

**Living plan.** Keep it current as development evolves: every phase updates its Status row, the Facts it changed and,
when a decision changes, the Decisions table. Each phase is a prompt file in `docs/prompts/todo/` (moved to
`docs/prompts/done/` when Juan accepts it); new phases are added here first, then as a prompt file.

## Objective (owner, 2026-10-29)

Contribute our **Azure Blob Storage backend** to upstream Atlas CMMS (`Grashjs/cmms`) **without changing anything
Enerkem changed** for SSO, licensing, packaging and the other options; those stay private.

1. `enerkem` keeps running production and keeps the release-tag merge policy (CLAUDE.md §2): merge upstream
   **v1.9.0** first and release it.
2. The Azure Blob code is brought to upstream quality **on `enerkem`** and copied verbatim to a PR branch built on
   the **latest upstream `main`** in the owner's fork `jarjona-enk/cmms` (identical bytes, below). Only the PR branch
   is built on upstream `main`; `enerkem` never merges `upstream/main`.
3. Juan pushes the branch and opens the PR. While it is open, every review change is made on `enerkem` and re-copied.
4. Once upstream releases a version containing it, `enerkem` merges that release (the Azure files merge as no-ops),
   adapts, and continues. **The fork is then no longer needed and Juan removes it.**

## Phases and status

Run each phase only on Juan's okay, in a clean context, on the model named; the next phase waits for his acceptance.

| phase | prompt | model, effort | status |
|---|---|---|---|
| 0 | [prepare: policy into CLAUDE.md, pre-flight](docs/prompts/todo/00-prepare.md) | Sonnet 5.5, low | todo |
| 1 | [merge upstream v1.9.0 into `enerkem`](docs/prompts/todo/01-merge-upstream-v1.9.0.md) | Opus 5.5, high | todo |
| 2 | [test v1.9.0 locally, land it, hand over the tag](docs/prompts/todo/02-test-land-v1.9.0.md) | Sonnet 5.5, medium | todo |
| 3 | [isolate the Azure Blob implementation on `enerkem`](docs/prompts/todo/03-isolate-azure-blob.md) | Sonnet 5.5, high | todo |
| 4 | [prepare the upstream PR branch](docs/prompts/todo/04-upstream-pr.md) | Sonnet 5.5, medium | todo |
| — | Juan pushes `contrib/azure-blob-storage` to `fork` and `origin`, opens the issue and the PR; review rounds | owner | waiting on Phase 4 |
| 5 | [after upstream releases it: merge back, retire the fork](docs/prompts/todo/05-merge-back-retire-fork.md) | Opus 5.5, high | waiting on upstream |

Model rule of thumb: upstream merges and conflict resolution in SSO, mail or storage code → **Opus 5.5**. Executing a
defined matrix, writing tests against a spec, copying files, prose → **Sonnet 5.5**. If a Sonnet session hits a failure
it cannot explain in two attempts, it stops and Juan reruns the phase on Opus 5.5.

## Directive for this whole exercise — LOCAL ONLY

> "All the work must be done locally. We don't touch production ever without me
> tagging and pushing."

- **No session touches production or any Azure resource** — not the web app,
  not its settings or logging, not the production database (no reads either),
  not the storage account, not the pipeline. No `az` commands. If a phase seems
  to need production, stop and report instead.
- **No session pushes to any remote (`origin` or `fork`) or creates tags**
  (amended 2026-10-29: the `fork` push is the owner's too). Sessions commit
  locally and end with the exact `git push` / `git tag` commands for the owner,
  and the list of branches not yet on `origin`. The owner deploys by tagging;
  the owner verifies production.
- Never push to `upstream` (push URL is `DISABLED`); never commit on `main`;
  never delete a branch.
- Local resources a session MAY use freely: the local Postgres (`atlas`
  database — wipe and restore at will after dumping), Docker Desktop and local
  containers (`cmms-minio`, `cmms-mailhog`, Azurite), ports 8080/8085/1025/
  8025/9000/10000, the scratchpad. Never kill a process the session did not
  start (another project's java often sits on 8080).

## How a phase is executed

Juan gives the okay for one phase; an agent with a clean context runs its prompt file on the model and effort written
on its first line. Wherever a phase says "stop and ask", the agent stops, records what it has in DEVELOPMENT-STATUS.md,
commits, and reports. Phase 2's manual SSO round-trip is a pause: the agent reports "ready for SSO" and resumes on
Juan's confirmation. Each phase fills its Cost section and updates its Status row above.

## Decisions taken — the phases assume these

| topic | decision |
|---|---|
| Frontend dependencies in the v1.9.0 merge | **Take upstream's `package.json` and `package-lock.json` as-is.** Our August within-major refresh is dropped; it was housekeeping. `npm ci`, never `npm install`. |
| Conflicts not covered by the standing rules | **Prefer upstream, log the choice in DEVELOPMENT-STATUS, continue.** Stop only if the conflict touches SSO, mail, AGPL/source-code, or Enerkem packaging (Dockerfile, startup.sh, pipeline, `.azure/`). |
| Test database | **Local only.** The local `atlas` database is a **copy of production** restored by the owner on 2026-10-19 (806 changesets, 7 users, 2 companies, 18 assets). Baseline dump: `atlas_backups\atlas-prodcopy-1.8.0-20261019.dump`. Phase 2 tests the fresh install on an empty `public` schema and the upgrade on this copy. Sessions never connect to the real production server. |
| Integration tests | Two things make Testcontainers work on Docker Desktop 29 (both in place 2026-10-19, verified): the daemon exposed on **tcp://localhost:2375** and **`api.version=1.44` in `%USERPROFILE%\.docker-java.properties`** — Docker 29 answers HTTP 400 to any API path below v1.40 and docker-java negotiates an older one by default (that 400 is the "Could not find a valid Docker environment" everyone sees). Sessions run tests with `DOCKER_HOST=tcp://localhost:2375`. If `curl http://localhost:2375/_ping` is not `200` or the properties file is missing, stop and ask. |
| SSO check in Phase 2 | **Port 8080 required** (the registered local redirect URI). If 8080 is busy, stop and ask; never kill the other process. |
| Pushes and tags | **Owner only** — `origin` and `fork` alike (2026-10-29). Sessions hand over commands. |
| Branches | **Never deleted**, `merge/upstream-*` and `contrib/*` included; every branch ends up on `origin`, `contrib/azure-blob-storage` too (2026-10-29). |
| Upstream PR | Phase 4 prepares `contrib/azure-blob-storage` from the latest `upstream/main`; **owner pushes it to `fork` and `origin` and opens the issue and the PR in the browser** (no `gh`). |
| GitHub identity | Fork `jarjona-enk/cmms`; remote `fork` = `git@github.com:jarjona-enk/cmms.git`; SSH key `~/.ssh/jarjona-enk` via `~/.ssh/config`. PR commits authored **`Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>`** (set per command with `git -c user.name=... -c user.email=...` on `contrib/*` only), **no `LLM:` line** (2026-10-29). `jarjona@enerkem.com` must be a verified e-mail on the `jarjona-enk` account for attribution. |
| Tests and security review | Our code only (CLAUDE.md "When coding software"). Phase 1 unit-tests the new `uploadAt`/`exists` and security-reviews the SSO and storage resolutions, so `release/1.9.0-enerkem.1` ships tested; Phase 3 completes the Azure tests (Azurite) and reviews SAS / managed identity; Phase 4 does a leak review (2026-10-29). |
| Licensing | Contributions go out under AGPLv3; upstream has no CLA. If maintainers ask for a CLA or relicensing grant, stop and bring it to the owner. |
| End state | After Phase 5 the fork is retired: the owner deletes `jarjona-enk/cmms` and the `fork` remote; CLAUDE.md drops the exception (2026-10-29). |

## Facts the phases rely on (gathered 2026-10-19)

| item | value |
|---|---|
| Our base | `enerkem` merged up to upstream **v1.8.0**; `UPSTREAM_VERSION=1.8.0`; production runs `release/1.8.0-enerkem.2` |
| Target | upstream **v1.9.0** = `fc27abfd` (2026-09-22), **402 commits**; `upstream/main` is 25 past it — never merge `upstream/main` |
| Big moves in v1.9.0 | Spring Boot **3.2.3 → 3.5.16** (Java 17 kept); `frontend/package.json` **removes axios, firebase, jsonwebtoken** (64k-line lockfile churn); `UserService` ±336 lines; `StorageService` gains `uploadAt(byte[], String, String)` and `exists(String)`; signed URLs cached via `CacheService.getCachedOrGenerateSignedUrl` |
| Hot spots touched | `WebSecurityConfig` (19), `OAuth2ClientRegistrationConfig` (10), `OAuth2AuthenticationSuccessHandler` (11), `EmailService2` (4), `api/Dockerfile` (12), `application.yml` (60), `docker-compose.yml` (27), `en.ts` (23), `api/pom.xml` (90) |
| Database | 8 new changesets (asset/location indexes, user session invalidation, refresh token, API-key lifecycle, optimistic-locking `version` columns, `UPDATE part SET version = 0`, user language). **No new PostgreSQL extensions.** Local baseline (production copy): 806 changesets, `unaccent` installed → expect **814** |
| Upstream deleted files we modified | none |
| Azure Blob footprint (ours) | commit `b90a0751`: `AzureBlobService.java` (new), `StorageType` `+AZURE`, `StorageServiceFactory` `+case`, `application.yml` `storage.azure.*`, `api/pom.xml` two deps. Upstream has no Azure backend (`StorageType = GCP, MINIO`) |
| Test suite | `mvn -DskipFrontend=true test` from `api/`, JDK 17, `DOCKER_HOST=tcp://localhost:2375`: **863 tests, 1 failure, 0 errors** on 2026-10-19 (full suite incl. Testcontainers, 1 min 36 s). The one failure is **expected**: `WorkOrderIntegrationTest$CreateTests.create_throwsForbiddenWhenUsageLimitExceeded` asserts the usage-based licence limit on active work orders, which our AGPLv3 decision removed (`LicenseService` grants every entitlement). Phase 1 must make the suite green by annotating that test `@Disabled("Enerkem: usage-based licence limits are removed under the AGPLv3 decision (DEVELOPMENT-STATUS 12.x)")` — never by restoring the limit. No Azure Blob tests exist yet |
| Local toolchain | JDK 17 at `C:\java\jdk-17`; Maven wrapper from `api/` (`.\mvnw.cmd -f ..\pom.xml`); if the wrapper misbehaves, `C:\Users\JArjona\.m2\wrapper\dists\apache-maven-3.8.6-bin\*\apache-maven-3.8.6\bin\mvn.cmd`; Postgres 18 `atlas/atlas` on `localhost:5432/atlas`, credentials in gitignored `dev.env`; `psql`/`pg_dump`/`pg_restore` in `C:\Program Files\PostgreSQL\18\bin`; the local `atlas` role cannot `CREATE DATABASE` — wipe and recreate the `public` schema instead |
| Local containers | Docker Desktop 29.9.1. `cmms-minio` and `cmms-mailhog` were recreated on 2026-10-19 and are running. If missing, recreate (read `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` from `dev.env`): `docker run -d --name cmms-minio -p 9000:9000 -p 9001:9001 -e MINIO_ROOT_USER=$MINIO_ACCESS_KEY -e MINIO_ROOT_PASSWORD=$MINIO_SECRET_KEY bitnamilegacy/minio:latest` (MinIO withdrew `minio/minio` from Docker Hub and `quay.io/minio/minio` needs a login; the Bitnami legacy image works and reads the same env vars) and `docker run -d --name cmms-mailhog -p 1025:1025 -p 8025:8025 mailhog/mailhog`. Redirect `docker run` output to a file — never pipe it into `head`. Azurite image `mcr.microsoft.com/azure-storage/azurite` is cached |
| Local run | `java -jar api/target/app.jar --server.port=PORT` with `dev.env` exported plus `MAIL_RECIPIENTS=cmms-admins@enerkem.test ENABLE_EMAIL_NOTIFICATIONS=true INVITATION_VIA_EMAIL=true SMTP_HOST=localhost SMTP_PORT=1025 SMTP_AUTH=false SMTP_STARTTLS=false PUBLIC_API_URL=http://localhost:PORT PUBLIC_FRONT_URL=http://localhost:PORT`. The SPA's API URL is baked at build time: build with `-Dfrontend.api.url=http://localhost:PORT`. Startup ≈ 30–50 s; wait for `Started ApiApplication` |
| Known traps | Git Bash converts UTF-8 command-line args through the ANSI codepage — send JSON bodies from files with `curl --data-binary @file` (write them with `printf '\xNN'`). `-DskipFrontend=true` also skips copying `frontend/build` into the jar. Heredoc-fed Python scripts break on quoting — write scripts to the scratchpad with the Write tool and run them by path. A `.wolf/` directory holds OpenWolf bookkeeping (ours, commit it). Another Claude session (cybermap) may run `taskkill //IM java.exe`; a java process or Maven build dying with no log is that, not a bug. C: drive is at 99 % (12 GB free); stop and ask if free space < 10 GB |
| Durable dumps | `C:\data\src\cmms\atlas_backups\` (gitignored and docker-ignored; exists). Baseline `atlas-prodcopy-1.8.0-20261019.dump` is there — never use the session scratchpad, which does not survive a session |


## Governing principle — identical bytes (owner, 2026-10-19)

> "Our PR is actually part of our code, so when it becomes part of the upstream
> code, it will update our own code with no changes."

The Azure Blob files on `enerkem` **are** the contribution, byte for byte: the
feature is brought to upstream quality on `enerkem` first (Phase 3); the PR
branch copies those files verbatim (Phase 4); every review change is applied
on `enerkem` the same day and re-copied; the upstream merge that brings it back
is a no-op for those files (Phase 5). Files under this rule:
`api/src/main/java/com/grash/service/AzureBlobService.java`, the Azure test
classes, the `AZURE` lines in `StorageType` / `StorageServiceFactory` /
`StorageServiceFactoryTest`, the `storage.azure.*` block in `application.yml`,
the Azure dependencies in `api/pom.xml`, `AZURE-setup.md`, and the Azure rows in
`README.MD`, `.env.example`, `docker-compose.yml`.

---

## PR text

*(filled in by Phase 4)*
