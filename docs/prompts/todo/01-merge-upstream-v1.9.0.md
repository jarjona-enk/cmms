# Phase 1 — merge upstream v1.9.0 into `enerkem`

**Model: Claude Opus 5.5, effort high.** 402-commit upstream merge with Spring Boot 3.2->3.5, SSO/mail conflict resolution and an interface change in AzureBlobService: a wrong resolution silently breaks production.

Phase 1 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

## Task

Read CLAUDE.md, DEVELOPMENT-STATUS.md (START HERE, §12.18, §12.23, §12.27)
and ENERKEM-PLAN.md (Directive, Decisions, Facts). Local only: no `az`, no
production, no pushes, no tags. Work on a merge branch; never commit on
`main`. Ask only for things the Decisions table does not settle.

**Pre-flight (stop and report if any fails):** `git branch --show-current`
is `enerkem` and the tree is clean (`.wolf/` and `.idea/` changes may be
committed or ignored); `.git/MERGE_HEAD` does not exist; `git fetch upstream
--tags` succeeds; `git rev-parse v1.9.0` is `fc27abfd…`; free space on C:
≥ 10 GB; JDK 17 at `C:\java\jdk-17`.

**Merge:**
1. `git switch main && git pull` (main tracks upstream/main), then
   `git switch enerkem`.
2. `git switch -c merge/upstream-v1.9.0 enerkem` and
   `git merge v1.9.0 --no-commit`. Do NOT merge `upstream/main`.
3. Resolve conflicts with these standing rules; everything not covered →
   prefer upstream and log the choice:
   - **SSO** (`WebSecurityConfig`, `OAuth2ClientRegistrationConfig`,
     `OAuth2AuthenticationSuccessHandler`): keep the `if (enableSso)` gate with
     the commercial-licence check removed, our SPA and `/source-code/**`
     permits, and the `OAUTH2_TENANT_ID` authority pinning; take everything else
     from upstream. The Administrator-role lookup stays upstream's typed API +
     our `.orElseThrow(CustomException)`.
   - **Mail** (`EmailService2`, `UserService`): keep our recipient logging,
     the `catch (Exception)` around the admin notification, the `invite()` log
     line and `@Transactional(Transactional.TxType.NOT_SUPPORTED)` on
     `EmailService2` (§12.23); take upstream's other changes.
   - **Frontend `package.json` + `package-lock.json`**: take upstream's both
     files unchanged (`git checkout v1.9.0 -- frontend/package.json
     frontend/package-lock.json`). Do not re-apply our pins.
   - **`api/pom.xml`**: keep our frontend-maven-plugin and resource-copy
     blocks and the two Azure dependencies; take upstream's Spring Boot
     3.5.16 and everything else.
   - **`api/Dockerfile`, `api/container/*`, `azure-pipelines.yml`,
     `.azure/**`, `scripts/**`, `infra/**`, and our root documents
     (`DEVELOPMENT-STATUS.md`, `REQUIREMENTS.md`, `ENERKEM-PLAN.md`,
     `CLAUDE.md`, `UPSTREAM_VERSION`)**: keep ours entirely.
   - **`application.yml`**: keep `storage.azure.*` and our SMTP parameters
     (`properties.mail.smtp.auth/starttls.enable` parameterised); take
     upstream's new keys.
   - `en.ts`, `.gitignore`, `docker-compose.yml`, `README.MD`: union.
4. **`AzureBlobService` must compile against the new `StorageService`:**
   implement `uploadAt(byte[] data, String filePath, String contentType)`
   (empty data → `CustomException` 400; overwrite at the exact path, set
   content type) and `boolean exists(String filePath)`; inject `CacheService`
   and route `generateSignedUrl(File, long)` through
   `cacheService.getCachedOrGenerateSignedUrl` exactly as `GCPService` does.
   Mirror `GCPService`'s error semantics. Javadoc on the new methods. **Unit-test them now**
   (decision 2026-10-29): create `AzureBlobServiceTest` (Mockito, no Docker) covering `uploadAt`
   (empty data -> 400; overwrite at the exact path, content type set), `exists` true/false, and that
   `generateSignedUrl(File, long)` goes through `CacheService`. Phase 3 extends this class.
5. Spring Boot 3.5 fallout: fix whatever no longer compiles (Thymeleaf
   `spring5` → `spring6` imports, Spring Security 6.5 API changes, Hibernate
   6.6 with the new `version` columns under `ddl-auto: validate`). Minimal
   changes; no refactors.
6. `echo 1.9.0 > UPSTREAM_VERSION` **inside the merge commit**. Commit the
   merge with a message listing every conflict and its resolution.

**Build and unit tests (required before this prompt ends):**
7. `cd api && .\mvnw.cmd -f ..\pom.xml -DskipTests package` with JDK 17 — full
   build, frontend included (10–15 min). Then `.\mvnw.cmd -f ..\pom.xml
   -DskipFrontend=true test` with `DOCKER_HOST=tcp://localhost:2375` (check
   `curl http://localhost:2375/_ping` is 200 first; if not, run the unit tests
   only with `-Dtest='!*IntegrationTest'` and say so). Target: **0 failures,
   0 errors** on the full suite. Fix test compilation/assertion fallout from
   the merge; never delete a test. The known pre-existing failure
   `WorkOrderIntegrationTest$CreateTests.create_throwsForbiddenWhenUsageLimitExceeded`
   is annotated `@Disabled` with the AGPLv3 reason (see Facts → Test suite);
   treat any *other* test that asserts a commercial-licence gate we removed
   the same way, and list each one in DEVELOPMENT-STATUS.
8. Verify byte-for-byte that our protected changes survived: `git diff enerkem
   merge/upstream-v1.9.0 -- <SSO files, EmailService2, UserService>` shows
   only upstream's additions, never a removal of ours.

**Record and stop:** update DEVELOPMENT-STATUS.md (new section: what v1.9.0
brought, each conflict and its resolution, every "preferred upstream" choice,
test numbers), CLAUDE.md "Current position" (merged to v1.9.0, next tag), the
cerebrum (new learnings) and the buglog (anything fixed). Commit on
`merge/upstream-v1.9.0`. Do NOT merge into `enerkem` — Phase 2 tests first.
End with `git log --oneline -5`.

## QA and acceptance

- Merge commit on `merge/upstream-v1.9.0` (kept), `UPSTREAM_VERSION` = `1.9.0` inside the merge commit; message lists
  every conflict and its resolution; `enerkem` not yet merged into.
- Full build (frontend included) succeeds with JDK 17; `mvn -DskipFrontend=true test` = **0 failures, 0 errors**; the
  usage-limit test (and any other commercial-licence test) `@Disabled` with the AGPLv3 reason, listed in DEVELOPMENT-STATUS.
- `AzureBlobServiceTest` exists and passes (uploadAt, exists, CacheService routing).
- Step 8 diff shows no removal of our SSO/mail changes.
- **Security review** (our code only): the SSO resolution (`if (enableSso)` gate, permits for the SPA and
  `/source-code/**`, tenant pinning, Administrator-role lookup) grants no unintended access; `uploadAt`/`exists` cannot
  write or probe outside the container or leak signed URLs/keys in logs. Findings recorded in DEVELOPMENT-STATUS.
- DEVELOPMENT-STATUS, CLAUDE.md "Current position", cerebrum and buglog updated.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation: to be filled (tokens in / out / cache read / cache write, cost in USD).
