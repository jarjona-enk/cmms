# Phase 4 — prepare the upstream pull request

**Model: Claude Sonnet 5.5, effort medium.** Verbatim file copy onto upstream/main, build on their toolchain, PR prose; no design decisions.

Phase 4 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

## Task

Read CLAUDE.md (§1 as amended by Phase 0), DEVELOPMENT-STATUS.md (the
Phase 3 section with the contribution file list) and ENERKEM-PLAN.md
(Directive, Governing principle, Decisions). Prepare the upstream PR branch;
do not push: the owner pushes it to `fork` and to `origin`, then opens the issue and the PR.

1. Remotes: `fork` = `git@github.com:jarjona-enk/cmms.git` (SSH, key
   `~/.ssh/jarjona-enk`) exists. Never touch `upstream`'s push URL
   (`DISABLED`); never push `enerkem` or `main` anywhere (only the owner does
   that, to `origin`).
2. `git fetch upstream && git switch -c contrib/azure-blob-storage upstream/main`
   — clean room on upstream's `main`, not on `enerkem`.
3. Re-apply **only** the contribution by **copying verbatim from `enerkem`**:
   `git checkout enerkem -- <each Azure file>` for the Azure-only files, and
   for shared files (`StorageType`, `StorageServiceFactory`,
   `StorageServiceFactoryTest`, `application.yml`, `api/pom.xml`, `README.MD`,
   `.env.example`, `docker-compose.yml`) apply exactly the Azure hunks from the
   Phase 3 list — no other Enerkem line may appear. If `upstream/main` has
   moved the storage interface since v1.9.0, adapt **on `enerkem` first**,
   commit there, then copy again (identical-bytes rule).
4. Build and test with upstream's toolchain: `cd api && mvn -B verify`
   (`DOCKER_HOST=tcp://localhost:2375`), including `AzureBlobServiceIT`.
   `git diff upstream/main --stat` must list only the contribution files.
   Anything else is a leak — remove it.
5. One commit, authored `git -c user.name="Juan F Arjona - Enerkem Inc"
   -c user.email=jarjona@enerkem.com commit -m "feat(storage): add Azure Blob
   Storage backend (STORAGE_TYPE=azure)"` with a body (no `LLM:` line on this upstream commit) describing the two auth
   modes, SAS behaviour (same browser-direct model as GCP/MinIO), the Azurite
   test and the docs.
6. Do **not** push. The owner runs `git push fork contrib/azure-blob-storage` and
   `git push origin contrib/azure-blob-storage` (every branch also lives on `origin`).
7. Write into the "PR text" section at the end of ENERKEM-PLAN.md: (a) the
   GitHub **issue** text to open first ("Feature request: Azure Blob Storage
   backend — I will submit a PR"), (b) the **PR** title and description
   (what it adds, configuration, how it was tested, that it runs in production
   at Enerkem since 2026-09 on Azure App Service with a managed identity),
   (c) the exact URL for the owner to open the PR:
   `https://github.com/Grashjs/cmms/compare/main...jarjona-enk:cmms:contrib/azure-blob-storage`.
   Commit that on `enerkem`. End by printing the two texts, the two push commands and the URL.

While the PR is open, the rule is: every review change is made on `enerkem`
first and re-copied to `contrib/azure-blob-storage`; `git diff enerkem
contrib/azure-blob-storage -- <contribution files>` must stay empty.

## QA and acceptance

- `contrib/azure-blob-storage` starts from `upstream/main`; `git diff upstream/main --stat` lists only the
  contribution files; `git diff enerkem contrib/azure-blob-storage -- <contribution files>` is empty.
- `mvn -B verify` green on upstream's toolchain, `AzureBlobServiceIT` included.
- One commit authored `Juan F Arjona - Enerkem Inc <jarjona@enerkem.com>`, no `LLM:` line.
- **Leak review:** no Enerkem SSO, licensing, packaging, host name, tenant/client id, secret or internal reference in
  the branch (grep the diff for `enerkem`, `10.225.`, `azurewebsites`, tenant/client ids from `dev.env`).
- Nothing pushed by the session; ENERKEM-PLAN.md "PR text" filled and committed on `enerkem`.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation: to be filled (tokens in / out / cache read / cache write, cost in USD).
