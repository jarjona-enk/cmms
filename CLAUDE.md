# CLAUDE.md — Atlas CMMS, Enerkem internal build

Maintain the status of this project and the software development on
DEVELOPMENT-STATUS.md. Always read it when you start and write all decisions,
changes, architecture changes, etc.

---

## 1. This is a downstream fork. Read this before any git operation.

This repo is an Enerkem-internal fork of the open-source Atlas CMMS project
(`Grashjs/cmms`, AGPLv3). Our modifications are documented in
DEVELOPMENT-STATUS.md and stay ours: **nothing here is ever contributed
upstream.**

| remote | URL | use |
|---|---|---|
| `origin` | Azure DevOps `EnerkemIT/New Services Implementations/cmms` | ours; push here |
| `upstream` | `https://github.com/Grashjs/cmms.git` | fetch only; push URL is `DISABLED` |

**Rules, in order of importance:**

1. **Never push to `upstream`.** Its push URL is deliberately set to the
   literal string `DISABLED` so any attempt fails loudly. Do not repair it.
2. **Never open a PR, issue, or patch against `Grashjs/cmms`.**
3. `main` is the Enerkem line and the Azure DevOps default branch. It carries
   our commits and is what CI builds and deploys.
4. Upstream is **not** mirrored to a local branch. It lives only as the
   `upstream/main` remote-tracking ref and upstream tags. Refresh with
   `git fetch upstream --tags`.
5. Never commit `dev.env`, a `LICENSE_KEY`, an Entra client secret, or
   anything from `dist/`. `dev.env` and `dist/` are gitignored — keep them so.

## 2. Merge policy: release tags only

**Only merge upstream when they publish a new release tag (`vX.Y.Z`). Never
merge `upstream/main`.**

`upstream/main` is their unreleased working line; at the time of writing it
sits 279 commits past their last tag. Merging it means absorbing untested
churn and re-resolving the same conflicts repeatedly. Release tags are the
only stable, reviewable integration points.

**Merge one tag at a time, oldest first.** Never skip a tag to reach a newer
one — the intermediate tag is what keeps each conflict set small enough to
reason about.

Procedure per tag:

```bash
git fetch upstream --tags
git switch -c merge/upstream-v1.7.0 main
git merge v1.7.0            # resolve, then build and smoke-test before merging on
echo 1.7.0 > UPSTREAM_VERSION   # REQUIRED, in the same merge - see below
git switch main && git merge --no-ff merge/upstream-v1.7.0
```

Always `merge`, never `rebase`. Rebasing replays our commits over theirs and
makes us resolve the same conflicts once per commit.

Never push upstream's `v*` tags to `origin`. A tag newer than our merge base
would drag its entire unreleased history into the Enerkem repo.

## 2a. Release tags MUST carry the upstream release number

Our release tags are:

```
release/<upstream release>-enerkem.<n>        e.g. release/1.6.0-enerkem.1
```

The first half names the upstream release this build is merged up to; `<n>`
counts our own releases on that base and **resets to 1** after each upstream
merge. Nothing else is accepted — the pipeline rejects `release/1.6.0`,
`release/v1.6.0-enerkem.1` and anything without the counter.

The repo-root file **`UPSTREAM_VERSION`** records the upstream release we are
merged up to (currently `1.6.0`). The pipeline reads it and fails the release
unless the tag's upstream half matches, so:

- **Bump `UPSTREAM_VERSION` inside the upstream merge itself**, never as a
  follow-up commit. A merge that forgets it makes every later tag either wrong
  or unreleasable.
- Do not hand-edit it to unblock a tag. If the tag says `1.7.0`, the fix is to
  merge upstream `v1.7.0`, not to change the file.

It is a file rather than a `git describe` because upstream's `v*` tags are not
mirrored into this repo (see above), so CI cannot see them.

### Current position

Base is `51341f8e` (2026-06-15), which is after upstream `v1.6.0`.

| tag | commits from our base | status |
|---|---|---|
| `v1.7.0` (2026-06-19) | +16 | **pending review** — do next |
| `v1.8.0` (2026-07-31) | +228 | pending, after v1.7.0 |
| `upstream/main` | +507 | never merge; unreleased |

**We are deliberately pinned to the current base.** Do not start the v1.7.0
merge on your own initiative — it is reviewed and scheduled by the repo owner.
Ask first.

### Known conflict hot spots

Measured against our base. When a merge touches these, expect work:

- `frontend/package.json` + `package-lock.json` — **the worst one.** Upstream
  has since *removed* axios, firebase and jsonwebtoken, while our dependency
  refresh bumped axios to ^1.7.9. Do not hand-merge the lockfile. Take
  upstream's both files, re-apply only the pins we still need, then
  `npm ci && npm run build`. Treat our dep-refresh commit as disposable.
- `frontend/src/i18n/translations/en.ts` — 23 upstream commits.
- `api/pom.xml` — 14. Our frontend-maven-plugin and resource-copy blocks live
  here; keep them, take their dependency changes.
- `WebSecurityConfig.java` — 10. Keep the `if (enableSso)` gate and our SPA
  permits.
- `api/Dockerfile` — 9. `OAuth2AuthenticationSuccessHandler.java` — 7.
  `docker-compose.yml` — 6.
- Zero upstream churn, so safe: `LicenseService.java`, `router/index.tsx`,
  `Login/Cover/index.tsx`, everything under `.idea/`.

### Keep the conflict surface small

When touching upstream files, prefer a config flag or a new file over an
inline edit. Every line we add to a file upstream also edits is a line we
re-resolve on every future merge.

## 3. Build essentials

Full detail in DEVELOPMENT-STATUS.md §2–3. The parts that break builds:

- **JDK 17.** The machine default JDK 26 breaks Lombok
  (`ExceptionInInitializerError: ... TypeTag :: UNKNOWN`). JDK 17 is at
  `C:\java\jdk-17`; set `JAVA_HOME` first.
- **Run `mvnw` from `api/`**, not the repo root — `.mvn` lives in `api/`.
- **`npm ci`, never `npm install`.** `npm install` rewrites the lockfile and
  drifts i18next into `TS2339: Property 'language' does not exist on type
  'i18n'`. If you see it: `git checkout -- frontend/package-lock.json`.
- Full build ≈10 min. Use `-DskipFrontend=true` for ~30s Java-only loops.
- Output is a single fat jar `api/target/app.jar` serving API + SPA on one
  port.
