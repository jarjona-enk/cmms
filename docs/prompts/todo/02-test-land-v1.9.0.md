# Phase 2 — test v1.9.0 locally, land it, hand over the tag

**Model: Claude Sonnet 5.5, effort medium.** Executes a fixed test matrix and lands the branch; escalate to Opus 5.5 only if a check fails twice without an obvious cause.

Phase 2 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

## Task

Read CLAUDE.md, DEVELOPMENT-STATUS.md (the Phase 1 section, §12.18 for the
recipe, §12.23) and ENERKEM-PLAN.md (Directive, Decisions, Facts). Local
only: no `az`, no production, no pushes, no tags. We are on
`merge/upstream-v1.9.0` with a green build. Stop and ask on any check that
fails twice without an obvious cause (then the owner reruns on Opus 5.5).

**Prerequisites:** Docker Desktop running and `curl http://localhost:2375/_ping`
= 200 (else stop); containers `cmms-minio` and `cmms-mailhog` running
(recreate with the commands in Facts → Local containers if missing); **port
8080 free** — if busy, stop and ask, never kill it; local Postgres up.

**Database baseline:** the local `atlas` database is a copy of production
(1.8.0 schema, 806 changesets, 7 users). A dump already exists at
`atlas_backups\atlas-prodcopy-1.8.0-20261019.dump`; take a fresh
`pg_dump -Fc` to `atlas_backups\atlas-prodcopy-1.8.0-<yyyymmdd>-pre-v190.dump`
anyway BEFORE anything else, and use that for the upgrade test.

**Build for 8080:** the jar from Phase 1 may be baked for another URL —
rebuild once: `cd api && .\mvnw.cmd -f ..\pom.xml -DskipTests
-Dfrontend.api.url=http://localhost:8080 clean package`. Verify the bundle hash
in `api/target/classes/static/index.html` equals `frontend/build/index.html`.

**Run (all on 8080, env as in Facts → Local run):**
1. **Fresh install:** drop and recreate the local `public` schema (`drop schema
   public cascade; create schema public;` as `atlas`), start the jar, expect
   Liquibase `Run: 814, Previously run: 0`, `Started ApiApplication`,
   `/health-check` 200, `/` 200 with `id="root"`.
2. **API suite** (JSON from files, `--data-binary`): signup → JWT; `/auth/me`
   role Administrator; create location/asset/work order with accented names;
   `POST /assets/search` with `{"field":"name","operation":"cn","value":"generatrice"}`
   finds `Génératrice` and with `GÉNÉ` too; work-order search; `POST /parts/search`
   200; `/api-docs.html` 200; `/source-code/download` 200 ≈ 93 MB; `/app/work-orders`
   200.
3. **Mail (MailHog API `http://localhost:8025/api/v2/messages`):** clear
   MailHog; `POST /users/invite` two addresses with `disableSendingEmail:false`
   → exactly 2 mails, each `To:` one invitee, no CC; resend one → 1 more mail;
   then `POST /users/invite` that address with `disableSendingEmail:true` and
   `POST /auth/signup` with `role:{id}` → HTTP 200 with a token, user row
   created, 1 mail `To: cmms-admins@enerkem.test` "New … registration".
   Restart with `SMTP_PORT=1`: repeat the registration → still **200** and an
   `ERROR … Admin notification … could not be sent to cmms-admins@…` log line.
4. **Browser (Playwright MCP):** login at `/account/login` with a user created
   above, Work Orders and Assets grids show the created rows; console has no
   errors other than the known `runtime-env.js` 500.
5. **SSO wiring:** `GET /oauth2/authorize/microsoft` → 302 to
   `login.microsoftonline.com/<OAUTH2_TENANT_ID from dev.env>/oauth2/v2.0/authorize`
   with `client_id=<OAUTH2_CLIENT_ID>` and
   `redirect_uri=http://localhost:8080/oauth2/callback/microsoft`. Then leave
   the instance running with `ENABLE_SSO=true` and tell the owner it is ready
   for the manual SSO round-trip; wait for the owner's confirmation before step 6.
6. **Upgrade path (production copy):** stop the jar; drop/recreate `public`;
   `pg_restore --no-owner --no-privileges` the pre-v190 dump; start → expect
   `Run: 8, Previously run: 806`, `UPDATE part SET version = 0` applied, and
   the production data intact by SQL: `select count(*) from own_user` = 7,
   `from asset` = 18, `from company` = 2 (a newly created test user cannot see
   other companies' data through the API, so verify in SQL). Then run the API
   suite again. Leave the database in this upgraded state.

**Land:** stop all local jars. `git switch enerkem && git merge --no-ff
merge/upstream-v1.9.0 -m "Merge branch merge/upstream-v1.9.0"`. Keep `merge/upstream-v1.9.0` (never delete branches). Update DEVELOPMENT-STATUS.md (matrix
with the numbers, SSO round-trip result as the owner reported it), CLAUDE.md
"Current position", memory. Commit on `enerkem`.

**Hand over (do not run):** print for the owner
`git push origin enerkem merge/upstream-v1.9.0`, `git tag release/1.9.0-enerkem.1`,
`git push origin release/1.9.0-enerkem.1` (counter resets after an upstream
merge), plus the production notes: no new extensions needed; 8 changesets run
at first start; the owner verifies `/health-check` on the azurewebsites host.

## QA and acceptance

- Fresh install: Liquibase `Run: 814, Previously run: 0`; `/health-check` 200; `/` 200 with `id="root"`.
- API suite, mail matrix (incl. the `SMTP_PORT=1` registration still 200 + ERROR log), browser check and SSO wiring
  all pass; Juan confirmed the manual SSO round-trip.
- Upgrade on the production copy: `Run: 8, Previously run: 806`; SQL counts 7 users / 18 assets / 2 companies; API
  suite passes again.
- `merge/upstream-v1.9.0` merged `--no-ff` into `enerkem` and **kept**; all local jars stopped.
- Hand-off prints the push/tag commands (incl. `merge/upstream-v1.9.0`) and the production notes; nothing pushed.
- No data leaves the machine: tests use only the local database, MailHog and local containers.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation: to be filled (tokens in / out / cache read / cache write, cost in USD).
