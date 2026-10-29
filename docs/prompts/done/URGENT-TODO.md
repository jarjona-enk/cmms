# URGENT TODO — adopt the shared development principles in cmms

**Model: Claude Sonnet 5.5, effort medium.** Documentation and planning work only (CLAUDE.md, ENERKEM-PLAN.md, new
prompt files); no code. Sonnet handles the plan conversion; Opus is not needed. Run it in a dedicated cmms session.

Asked by Juan on 2026-10-29 (from the budget session): apply the software development principles of
`C:\data\src\budget\CLAUDE.md` to every project, respecting each project's own guidelines. cmms was **parked** for
its own session. Do NOT change cmms' principles (fork rules, LOCAL ONLY, identical bytes, merge policy, release tags,
infra parked, build essentials); change only the **way of working**: plan first, then implement.

## Decisions already taken by Juan (2026-10-29) — apply them, do not re-ask

1. **Branches.** Never delete branches, local or remote, merged or not — including `merge/upstream-*`. Change the
   CLAUDE.md §2 procedure: drop `git branch -d merge/upstream-vX.Y.Z`. Every branch must end up on **our** remote
   (`origin`, Azure DevOps), never on `upstream`. Juan pushes; Claude never pushes (consistent with LOCAL ONLY) and
   lists, at each hand-off, the branches not yet on `origin`.
2. **Commit messages.** No `Co-Authored-By` line; add one line with the model used: `LLM: Claude <model>`.
   (Check the upstream-PR authorship rule in ENERKEM-PLAN.md / cerebrum: it governs commits sent upstream through
   the `fork` remote; keep it if it conflicts and ask Juan.)
3. **Logging, configuration, secrets** (budget CLAUDE.md "When coding software"): every exception logged, never
   swallowed, with context and no secrets; configuration env-var driven, never hardcoded; never commit a secret,
   warn if one is committed, keep local secret files git-ignored.
   - cmms' committed, non-secret `.azure/env/prod.env` (pushed as app settings, read as env vars) is **compliant**:
     keep it, and say so in CLAUDE.md.
4. **Scope in this fork.** Unit tests, javadoc and the logging rules apply to **our code only**: new Enerkem files
   and the lines we change in upstream files. Never retrofit upstream code (it adds conflicts on every merge;
   "keep the conflict surface small" still rules).
5. **Planning flow.** Only small fixes/changes on the fly; everything else is planned as a prompt in
   `docs/prompts/todo/` (create it), moved to `docs/prompts/done/` when Juan accepts the result. Each prompt has:
   a first line with the most cost-efficient model + effort level; every question resolved (never assume, ask);
   self-sufficient pointers; a "QA and acceptance" section; a final "Cost" section (tokens in/out/cache, cost),
   kept up to date. Implementation only on Juan's okay, by an agent with a clean context on that model/effort.
   `DEVELOPMENT-STATUS.md` keeps recording decisions and changes, as today.
6. **Convert the existing plan.** `ENERKEM-PLAN.md` stays as the roadmap index and keeps its principles (LOCAL
   ONLY directive, how prompts are executed, decisions of 2026-10-19, facts, governing principle "identical bytes",
   PR text). Prompts 1-5 (not started; Prompt 0 = owner decisions, done) each become a file in
   `docs/prompts/todo/` in the new format, linked from ENERKEM-PLAN.md, without changing what they ask.

7. **Test and security review** (budget CLAUDE.md, added 2026-10-29), in the "When coding software" section:
   - Where the code permits network access, executes authentication, or defines roles and access rights: before closing a feature, do a code review for security vulnerabilities, attack vectors, or side effects permitting unintended permissions.
   - Execute a test/review to ensure the code does not produce data loss or exposes data/secrets/information outside the organization.
   In this fork it applies to our code only (decision 4).

## Answers from Juan (2026-10-29, cmms session) — apply them, do not re-ask

8. **Model per prompt:** re-assess each prompt and write the most cost-efficient current model + effort, with a
   one-line reason (do not just map "Opus 5"/"Sonnet 5" to 5.5).
9. **Upstream commits:** NO `LLM:` line on `contrib/*` commits sent upstream through `fork`; those keep the existing
   upstream-PR rule (author `Juan F Arjona - Enerkem Inc`, PR text only). The `LLM:` line applies to our commits.
10. **Folders:** `docs/prompts/todo/` and `docs/prompts/done/` exist, each with an empty `.gitkeep` to commit.
11. **This file:** at the end, `git mv` it to `docs/prompts/done/URGENT-TODO.md` with the Cost section filled.

## Steps

1. Read `CLAUDE.md`, `ENERKEM-PLAN.md`, `.wolf/cerebrum.md` (User Preferences), `C:\data\src\budget\CLAUDE.md`
   ("Rules" and "When coding software"). Ask the open question.
2. Edit cmms `CLAUDE.md`: add a "Rules" section (1, 2) and a "When coding software" section (3, 4, 5, 7) adapted to
   the fork; fix §2's procedure (no branch deletion). Keep every existing principle; keep it concise.
3. Create `docs/prompts/todo/` and convert Prompts 1-5 (decision 6); update ENERKEM-PLAN.md to link them.
4. Update `.wolf/cerebrum.md` User Preferences where they contradict the new flow (one line each), and add a line
   to `DEVELOPMENT-STATUS.md`.
5. Commit on `enerkem` (LLM line). Do not push. Delete this file in the same commit only if Juan agrees; otherwise
   move it to `docs/prompts/done/URGENT-TODO.md` with the Cost section filled.

## QA and acceptance

- CLAUDE.md keeps all of §1-§3 principles; only the procedure line about deleting merge branches changed.
- Rules 1-5 and 7 are in CLAUDE.md; ENERKEM-PLAN.md links five prompt files, each with model/effort, decisions,
  QA/acceptance and Cost sections, and the same content as before.
- `git diff` touches only docs/rules files; no code, no infra, no pipeline.
- Juan reviews and accepts.

## Cost

- Planning (written in the budget session, 2026-10-29): part of that session's cost, not tracked separately.
- Implementation (cmms session 2026-10-29, Claude Opus 5.5; transcript totals before the commit): input 54,
  output ~34k, cache read ~2.61M, cache write ~105k (1h TTL) tokens -> about **US$2.0** at $4 / $20 / $0.20 / $8 per MTok.
  The same work on Sonnet 5.5 (as this file recommended) would have cost about US$1.3.
- Outcome: Juan's 2026-10-29 objective replaced decision 6's one-to-one conversion: ENERKEM-PLAN.md is the living
  plan and Prompts 0-5 are phase files `docs/prompts/todo/00..05-*.md` (DEVELOPMENT-STATUS 12.29).
