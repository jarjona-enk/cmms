# Phase 0 — prepare: write the contribution policy into CLAUDE.md, pre-flight the local setup

**Model: Claude Sonnet 5.5, effort low.** Exact text edits to two documents from this file plus read-only checks; no
code, no judgement calls.

Phase 0 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

Why: the owner decisions of 2026-10-19 (old "Prompt 0") were recorded in ENERKEM-PLAN.md and the cerebrum but never
written into CLAUDE.md or DEVELOPMENT-STATUS.md; Phases 1 and 4 rely on them (§12.27, "§1 as amended by Phase 0").
The 2026-10-29 decisions change one point: **sessions never push, not even to `fork`**; the owner pushes.

## Task

Work on `enerkem` (`git branch --show-current`; never commit on `main`). Make these edits:

1. **CLAUDE.md §1, opening paragraph:** replace *"Our modifications are documented in DEVELOPMENT-STATUS.md and stay
   ours: **nothing here is ever contributed upstream.**"* with: *"Our modifications are documented in
   DEVELOPMENT-STATUS.md and stay ours: **nothing here is contributed upstream, with one sanctioned exception: the
   Azure Blob Storage backend**, via the owner's fork `jarjona-enk/cmms`, under AGPLv3 (see ENERKEM-PLAN.md). SSO,
   licensing, packaging and every other Enerkem change stay private. Once upstream releases the Azure backend and we
   merge it back, the fork is retired."*
2. **CLAUDE.md §1 remotes table:** add the row
   `| `fork` | `git@github.com:jarjona-enk/cmms.git` | owner's GitHub fork for the Azure Blob PR; `contrib/*` only; the owner pushes |`.
3. **CLAUDE.md §1 rule 2:** change to *"**Never open a PR, issue, or patch against `Grashjs/cmms`** — the only
   exception is the owner's Azure Blob PR (ENERKEM-PLAN.md), which the owner opens; sessions never do."*
4. **CLAUDE.md §1, new rule 6:** *"**All development and testing is local.** No session touches production or Azure
   resources, pushes to any remote (`origin` or `fork`), or creates tags; the owner does that. Sessions commit
   locally and hand over the exact commands."*
5. **DEVELOPMENT-STATUS.md:** new section `### 12.27 Policy decisions for the v1.9.0 / Azure contribution work
   (2026-10-19, amended 2026-10-29)` placed before §12.28, copying the **Directive** and **Decisions** sections of
   ENERKEM-PLAN.md verbatim.
6. **Pre-flight, read-only — report, do not fix:** `git remote -v` shows `origin`, `upstream` (push `DISABLED`) and
   `fork`; `git ls-remote fork` succeeds over SSH (key `~/.ssh/jarjona-enk`); `atlas_backups\` exists and holds
   `atlas-prodcopy-1.8.0-20261019.dump`; free space on C: >= 10 GB; `C:\java\jdk-17` exists;
   `curl http://localhost:2375/_ping` = 200; `%USERPROFILE%\.docker-java.properties` contains `api.version=1.44`;
   `docker ps` lists `cmms-minio` and `cmms-mailhog`; local Postgres answers on `localhost:5432`. Record each result
   in the Phase 0 row of ENERKEM-PLAN.md -> Status and in DEVELOPMENT-STATUS §12.27; anything failing is a blocker
   for Phase 1 that Juan resolves.
7. Commit on `enerkem`: `docs: policy - local-only development; Azure Blob backend may be contributed upstream`
   (+ `LLM:` line). End with `git log --oneline -3`, the branches not yet on `origin`, and the command for the
   owner: `git push origin enerkem`.

Do not start Phase 1.

## QA and acceptance

- `git diff HEAD~1 --stat` touches only CLAUDE.md, DEVELOPMENT-STATUS.md, ENERKEM-PLAN.md and this file.
- CLAUDE.md §1 has the exception sentence, the `fork` row, amended rule 2 and rule 6; rules 1, 3, 4, 5 unchanged.
- DEVELOPMENT-STATUS §12.27 exists and matches ENERKEM-PLAN.md Directive + Decisions.
- Pre-flight results recorded; nothing pushed, no tag, no production or Azure access.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation (2026-10-29, Sonnet 5.5 low, clean agent): ~80k tokens total, 16 tool calls, 3 min (in/out/cache split not reported by the harness) -> about US$0.10-0.20.
