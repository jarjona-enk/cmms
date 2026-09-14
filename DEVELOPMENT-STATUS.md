# Development Status — Atlas CMMS internal build (Entra SSO + single-jar + AGPL)

> Context hand-off for another session. Last updated: 2026-09-11 by jarjona@enerkem.com.
> Project = **Atlas CMMS** (open-source, AGPLv3/commercial dual-licensed).
> Stack: backend Java **Spring Boot** (`api/`), frontend **React/TS** (`frontend/`), `mobile/` (RN, untouched).

---

## START HERE — state as of 2026-09-11

Read `CLAUDE.md` first: this is a **downstream fork** and the git rules are strict.

**Where we are.** Production infrastructure was built **by hand** and is ready.
The pipeline is production-only and creates nothing. **OpenTofu is parked** for
a later release — see `infra/README.md`; do not apply it.

Nothing has been released yet: the ACR repository does not exist and the
pipeline has never run.

| Area | State |
|---|---|
| Fork boundary | Done. `origin` = Azure DevOps, `upstream` = GitHub, push `DISABLED` |
| Merge policy | Done. Release tags only. Pinned to base `51341f8e` (post-v1.6.0) |
| Build → single fat jar | **Verified 2026-09-10**: full container build, boots to `/health-check` in 7s, serves the SPA, deep links and the AGPLv3 source bundle |
| Entra SSO, AGPLv3 §13 | Done |
| Azure Blob storage backend | Code done. Account `stgcaneastcmms` + container `cmms` exist, and the app identity already has Blob Data Contributor **and** Blob Delegator |
| Container SSH + log file | **Verified.** sshd on `0.0.0.0:2222`, app on `:::8080`, log teed to `/home/cmms/atlas.log` |
| CI/CD pipeline | **Production-only, single job.** Build → smoke-test → push → attach to `cmms` + app settings → verify. Creates no infrastructure. Never run |
| Deployment settings | `.azure/env/prod.env`, committed, non-secret. No Azure DevOps variable group |
| Secrets | Key Vault references, never touched by the pipeline. `scripts/setup-keyvault.ps1` does the whole setup from `prod.env`. **Vault not created yet** |
| OpenTofu infra | ⏸ **PARKED.** Never applied, and must not be applied — it would build a parallel set of resources |
| Production web app `cmms` | Exists, hand-built, Running. Needs secrets + the identity fix before a container can boot |
| ACR repository `cmms` | **Does not exist.** Nothing has ever been pushed |
| `cmms.enerkem.com` | **Does not exist.** NXDOMAIN, no hostname binding on the app |

### The hand-built production environment

| Resource | Value | Notes |
|---|---|---|
| Web app | `cmms` in `New-Implementations` | **site containers** app; `linuxFxVersion` is the literal `sitecontainers`. On shared plan `ASP-dev-pmo-project-tracking-a972` (B3). Breaks the `<env>-<app>` naming convention |
| Identity | user-assigned `ua-id-9ca4` | client `dbb349c1-…`, principal `11b7cf2e-710f-4401-987d-4f98e466486b` |
| Database | `atlas` / `atlas` on `db-caneast-pmdms` | reached at `10.225.1.104:5432` — IP, not FQDN (§12.4) |
| Storage | `stgcaneastcmms`, container **`cmms`** | ⚠️ **`publicNetworkAccess: Disabled`**, `defaultAction: Deny`, private endpoint only — see below |
| Registry | `enerkem.azurecr.io/cmms` | repository does not exist yet |

### Blocking the first release

1. **Secrets and the identity fix.** Run
   `.\scripts\setup-keyvault.ps1` (try `-WhatIf` first). It creates
   `enkm-cmms-prod`, grants both roles, loads the three secrets from the
   repo-root `prod.env`, repoints `keyVaultReferenceIdentity` at `ua-id-9ca4`,
   and sets the referencing app settings. Verified working in `-WhatIf`;
   see REQUIREMENTS.md §2.
2. **DNS + hostname binding + certificate for `cmms.enerkem.com`.** Must be in
   place *before* the first release build: the URL is compiled into the SPA
   bundle at image build time.
3. **`git push origin main`** — the remote is still behind.
4. **Decide the storage-account question below.**

Done since: ✅ Website Contributor granted to the deploy service principal,
✅ pipeline authorised for the Azure service connection, ✅ duplicate pipeline
removed, ✅ service connection ids corrected (§12.11).

### Open items

- ⚠️ **`stgcaneastcmms` is unreachable from browsers.** Public network access is
  disabled with `defaultAction: Deny` and a single private endpoint. But
  `FileMapper` hands the browser a signed SAS URL and the API never proxies file
  bytes — so the *app* can upload through the private endpoint while every
  attachment, image, thumbnail and export **download in the UI fails**. Three
  ways out: (a) enable public network access, which is what the parked Tofu
  config assumed and is safe because SAS still gates every object and
  `allowBlobPublicAccess` stays false; (b) confirm corporate DNS resolves
  `stgcaneastcmms.blob.core.windows.net` to the private endpoint for end-user
  machines, which makes it work for internal users only — the same question as
  the database FQDN in §12.4; (c) front it with something and set
  `AZURE_STORAGE_ENDPOINT`, remembering SAS signatures are host-bound. **Not yet
  decided.**
- ⚠️ **First release changes the web app's shape.** `AzureWebAppContainer@1`
  sets `linuxFxVersion` to `DOCKER|<image>`, moving `cmms` off the
  site-containers model. Functionally identical for one container on 8080, but
  it is a change to a hand-built app. `azure-pipelines.yml` has a commented-out
  `az webapp sitecontainers update` alternative.
- **Rotate `OAUTH2_CLIENT_SECRET`** — it sits in `dev.env` and `prod.env` on
  disk, and was inside the AGPLv3 source bundle until 2026-09-10 (§12.5). No
  such image was ever pushed, but treat it as exposed.
- `AZURE_STORAGE_ENDPOINT` in the repo-root `prod.env` now correctly reads
  `https://stgcaneastcmms.blob.core.windows.net`, which is also the default, so
  it is no longer a problem. The committed `.azure/env/prod.env` leaves it
  unset on purpose.
- **No test environment.** `test/*` tags build nothing. The in-pipeline smoke
  test stands in for it.
- SSO auto-provisioning still creates a **new org per first-of-domain user**,
  probably wrong for an internal rollout. Unchanged.
- Upstream `v1.7.0` (+16 commits) pending review — **never merge unprompted.**
- **No live runtime test in Azure has happened.** Everything verified so far was
  verified locally in Docker.

### Verified locally, 2026-09-10

Worth not re-doing: full image build; boot to `/health-check` in 7s against a
throwaway Postgres; `netstat` showing `0.0.0.0:2222` (sshd) and `:::8080` (app);
the complete Spring log in `/home/cmms/atlas.log`; SPA shell, deep link and
source bundle all served.

Session-level detail — decisions, mistakes, preferences — is in `.wolf/cerebrum.md`,
`.wolf/memory.md` and `.wolf/buglog.json`.

---

## 0. Frontend dependency upgrade (2026-06-19) — DONE, build green

Scope chosen by user: **Safe** = latest minor/patch within current major, fix breakage, keep React 17 / CRA / MUI 5 / router 6, **app must stay buildable**. Validated: `cd frontend; npm run build` → "build folder is ready to be deployed".

**Upgraded to latest within-major** (~60 pkgs via `npm-check-updates --target minor`): `@emotion` 11.14, `@reduxjs/toolkit` 1.9.7, `react-redux` 8.1.3, `react-router-dom` 6.30.4, `formik` 2.4.9, `date-fns` 2.30, `firebase` 9.23, `recharts` 2.15.4, `apexcharts` 3.54.1, `@fullcalendar` 5.11.5, `eslint` 8.57.1, `@typescript-eslint` 5.62, `prettier` 2.8.8, `typescript` 4.7.3→**4.9.5**, plus many `@types/*`. Intentional major: **`axios` 0.27→^1.7.9** (only used in `src/utils/axios.ts`, compatible).

**Held at known-good (NOT bumped) — newer versions break the build; deferred to the bigger React18/MUI7/TS5 migration:**
- `@mui/material` + `@mui/icons-material` + `@mui/lab` + `@mui/styles` → **kept 5.8.x**. MUI 5.18 tightened `Select`/`Autocomplete` value generics (`string` vs `string|number`) → breaks many form call sites.
- `@mui/x-data-grid` → **kept 5.17.3**. 5.17.26 regressed `GridActionsCellItem` props (required `onResize`/`onResizeCapture`).
- `i18next` → **pinned 25.7.1** (not 25.10.10) and `react-i18next` → **kept 11.17.0** (not 15). react-i18next 15 / newer i18next 25.x ship **TS-5-only `.d.ts` syntax** (`const` type params) that TypeScript 4.9 can't parse → `i18n.language` type is lost (`TS2339`). The CRA build tolerates i18next's `node_modules` d.ts (fork-ts-checker filters node_modules), but standalone `tsc`/IDE will show i18next parse noise — pre-existing, not a regression.
- `typescript` kept on 4.x (user declined the TS-5 path). **Moving to react-i18next 15 / i18next latest / MUI 7 requires TS 5 first.**

**Code fixes applied:**
- `react/jsx-key` (new eslint-plugin-react 7.37): added `key` in `CompanyProfile/CompanyDetails.tsx` and `WorkOrders/index.tsx`.
- `GridActionsCellItem`: added `showInMenu={false}` in 5 grid files (AssetParts/AssetFiles/AssetDowntimes/Roles/Checklists) — harmless under 5.17.3, future-proofs for the grid upgrade.
- `SelectForm.tsx`: one extra `// @ts-ignore` on `options` (harmless under MUI 5.8).

**Lockfile:** `frontend/package-lock.json` regenerated (intended). Frontend build still uses `npm ci` (api/pom.xml) — the new lock is the new known-good.

**Caveat / not done:** runtime QA not performed (build-only). The held libs mean this is NOT "everything on absolute latest" — that's the declined "Full" scope (React 19 + MUI 7 + Vite + TS 5 + replace abandoned libs).

---

## 1. What we are doing (goals, in order)

1. **Enable Microsoft Entra SSO** on this internal deployment — **decided: stay on AGPLv3**, so we removed the commercial-license gate that blocked SSO (see §3).
2. **AGPLv3 §13 compliance** — the modified app must offer its complete corresponding source to users. Added a public `/source-code` page + a downloadable source bundle baked into the jar.
3. **Single self-contained fat jar** that serves BOTH the REST API and the React UI on one port (single origin → no CORS, one OAuth redirect URI).
4. **Easy Linux server deploy** via `systemd` (`cmms.service`), env from a `.env` next to the jar, logs to `cmms.log`.

All four are **implemented and the full build is validated end-to-end** (jar contains the SPA). Not yet done: a live runtime smoke test (needs Postgres + MinIO), and the optional SSO hardening in §7.

---

## 2. HOW TO BUILD & RUN (start here)

**Prereqs / gotchas (IMPORTANT):**
- **Use JDK 17.** The machine default is JDK 26 which **breaks Lombok** (`ExceptionInInitializerError: com.sun.tools.javac.code.TypeTag :: UNKNOWN`). JDK 17 is at `C:\java\jdk-17`. Always `:$env:JAVA_HOME="C:\java\jdk-17"` first.
- **Maven wrapper must run from `api/`** (the `.mvn` dir lives there, not at repo root). System `mvn` also exists at `C:\java\maven`.
- **Frontend installs use `npm ci`, NOT `npm install`.** `npm install` rewrites `package-lock.json` and drifts `i18next`/`react-i18next` into a TS compile error (`TS2339: Property 'language' does not exist on type 'i18n'` in `App.tsx:117`). If you ever see that error: `git checkout -- frontend/package-lock.json` and use `npm ci`. `.npmrc` already sets `legacy-peer-deps=true`.
- **PowerShell mangles `-Dkey=http://host:8080`** (the `://` splits). Quote it or rely on pom defaults. The build scripts handle quoting.
- First full build is **~10 min** (Node download + `npm ci` + CRA production build). Use `-DskipFrontend=true` for ~30s Java-only iteration.

**Full build (frontend + fat jar):**
```powershell
$env:JAVA_HOME="C:\java\jdk-17"
cd C:\data\src\cmms\api
.\mvnw.cmd -DskipTests clean package        # -> api/target/app.jar  (contains API + SPA)
```
**Java-only (skip slow frontend):** `.\mvnw.cmd -DskipTests -DskipFrontend=true clean package`
**Quick SPA-only rebuild (dev):** `./scripts/build-frontend.ps1` then `cd api; .\mvnw.cmd spring-boot:run`
**Release wrapper:** `./scripts/build.ps1` → also makes AGPL source bundle and stages `dist/{atlas-cmms.jar,.env,cmms.service}`.

**Run locally (needs Postgres + MinIO):**
```bash
# from Git Bash
docker compose up -d postgres          # or a local Postgres at localhost:5432/atlas
./scripts/run-minio.ps1                # local MinIO using dev.env creds (or blank MINIO_* to skip files)
set -a; source dev.env; set +a; java -jar api/target/app.jar
```
**App URL: http://localhost:8080** (Spring serves the SPA; login page there; SSO returns to `/oauth2/success`).

---

## 3. Build architecture (how the jar is assembled)

- **`api/pom.xml`** holds the frontend build (NOT the root pom — see why below):
  - `frontend-maven-plugin:1.15.0` installs hermetic **Node v21.6.1**, runs `npm ci`, then `npm run build` with `REACT_APP_API_URL/ENABLE_SSO/OAUTH2_PROVIDER` baked from pom properties (`frontend.api.url` default `http://localhost:8080`, `frontend.enable.sso=true`, `frontend.oauth2.provider=microsoft`). Bound to `generate-resources`. Skippable via `-DskipFrontend=true` (`<skip>${skipFrontend}</skip>`).
  - `maven-resources-plugin` copies `../frontend/build` → `${project.build.outputDirectory}/static` (= `target/classes/static`) at `prepare-package`, so `spring-boot:repackage` bundles it. **Keeps `src/main/resources` clean.**
- **Root `pom.xml`** is just an aggregator (`packaging=pom`, module `api`). The frontend build CANNOT live here: api's parent is `spring-boot-starter-parent`, so Maven builds the **api module before the aggregator** (reactor order observed: `api` then `cmms`). A root-level copy would run after the jar is packaged → SPA missed. This was a real bug caught during validation.
- **Spring serves the SPA from `classpath:/static`** at root. `SpaForwardController` forwards deep links to `index.html`. `WebSecurityConfig` permits the SPA shell/routes and `webSecurityCustomizer` ignores SPA static assets.
- **`finalName=app`** → jar is `api/target/app.jar`.
- Verified inside the jar: `BOOT-INF/classes/static/{index.html,asset-manifest.json,static/js,static/css}` AND the committed api assets `static/{api-docs.html,css/,images/logo.png}` are both present (no clobbering).

---

## 4. SSO change (AGPLv3 path — license gate removed)

- `WebSecurityConfig.java` (~line 91): changed `if (enableSso && licenseService.isSSOEnabled())` → **`if (enableSso)`**. SSO now gated only by `ENABLE_SSO`. No `LICENSE_KEY` needed. `licenseService` field left injected (harmless).
- Existing Entra support (unchanged, already in repo):
  - `OAuth2ClientRegistrationConfig.java:40-52` — `microsoft` client → `login.microsoftonline.com/common/oauth2/v2.0/{authorize,token}`, JWKS, Graph `oidc/userinfo`, scopes `openid email profile`, `client_secret_post`.
  - `OAuth2AuthenticationSuccessHandler.java` — extracts email (`preferred_username` fallback), find-or-create user, mints app JWT, redirects to `${PUBLIC_FRONT_URL}/oauth2/success?token=`.
  - Frontend "Continue with SSO" → `${apiUrl}oauth2/authorize/microsoft` (`LoginJWT.tsx`).
- **Entra app registration needed:** redirect URI `${PUBLIC_API_URL}/oauth2/callback/microsoft`; Graph delegated `openid email profile`; a client secret.

---

## 5. AGPL §13 source availability (implemented)

- `api/.../controller/SourceCodeController.java` — public `GET /source-code/download` streams `classpath:/static/source/atlas-cmms-source.zip`.
- The zip is generated by `scripts/build-source-bundle.{ps1,sh}` (whole repo minus `.git`/`node_modules`/`target`/build dirs; ~76 MB) into `api/src/main/resources/static/source/`, and also by the `api/Dockerfile` `source` stage.
- Frontend `/source-code` page (`frontend/src/content/pages/SourceCode/index.tsx`) — Download button + "request via IT ticket" text. Linked from login page (`Auth/Login/Cover/index.tsx`) and the sidebar footer. i18n key `source_code_notice` in `en.ts`.

---

## 6. Deploy artifacts & config

- **`cmms.service`** (systemd): `WorkingDirectory=/opt/cmms`, `EnvironmentFile=/opt/cmms/.env`, `StandardOutput/Error=append:/opt/cmms/cmms.log`, runs `java --add-opens=java.base/java.lang=ALL-UNNAMED -jar /opt/cmms/atlas-cmms.jar`. Install steps in the file footer. (Needs systemd v240+ for `append:`; older-systemd fallback noted in file.)
- **`dev.env`** (repo root, **now gitignored**, was untracked): single-origin values `PUBLIC_API_URL=PUBLIC_FRONT_URL=API_URL=http://localhost:8080`; DB `atlas`/`4tl4s` at `localhost:5432/atlas`; MinIO `minio`/`minio123`; SSO `ENABLE_SSO=true OAUTH2_PROVIDER=microsoft` with a **real client id + secret pasted in** (⚠️ ROTATE that secret — it was written to disk; see §8). `GOOGLE_KEY` blank (Google Maps only, optional).
  - ⚠️ `API_URL` is **baked into the SPA at build time** — set it to the server's public URL in `dev.env` BEFORE building for a server.
- **`docker-compose.yml`** has `build:` sections (api builds from repo-root context via `api/Dockerfile`; frontend from `./frontend`). `api/Dockerfile` build stage now runs `mvn -f pom.xml -DskipTests clean package` (whole reactor incl. frontend) and copies the jar from `api/target`.
- **`.dockerignore`** keeps the repo-root build context lean.
- **MinIO** is needed only for file attachments/exports. `MinioService.init()` (`@PostConstruct`): if any `MINIO_*` var is empty it no-ops (app boots; uploads error when used); if set but unreachable, **app fails to start**. Bucket `atlas-bucket` auto-created. `scripts/run-minio.{ps1,sh}` start a local container with dev.env creds.

---

## 7. Full list of files created/modified this work

**Backend:** `api/src/main/java/com/grash/configuration/WebSecurityConfig.java` (SSO gate removed + SPA/static permits), `api/.../controller/SourceCodeController.java` (new), `api/.../controller/SpaForwardController.java` (new), `api/pom.xml` (frontend-maven-plugin + resources copy + props), `api/Dockerfile`, `api/.gitignore` (ignore generated SPA under `static/` + `static/source/`).
**Root:** `pom.xml` (aggregator, packaging pom), `docker-compose.yml`, `.dockerignore` (new), `.gitignore` (ignore `dev.env`, `dist/`), `dev.env` (new), `cmms.service` (new).
**Frontend:** `content/pages/SourceCode/index.tsx` (new), `router/index.tsx`, `content/pages/Auth/Login/Cover/index.tsx`, `layouts/ExtendedSidebarLayout/Sidebar/SidebarFooter/index.tsx`, `i18n/translations/en.ts`.
**Scripts (new):** `scripts/build.{ps1,sh}`, `scripts/build-frontend.{ps1,sh}`, `scripts/build-source-bundle.{ps1,sh}`, `scripts/run-minio.{ps1,sh}`.

Nothing committed yet — all changes are in the working tree on branch `main`.

---

## 8. Open issues / things to fix next

- [ ] **ROTATE the Entra client secret** in `dev.env` (it was written to a file; `dev.env` is now gitignored but the value on disk should be considered exposed).
- [ ] **Live smoke test** not yet run: start Postgres + MinIO, run `api/target/app.jar`, confirm login page at http://localhost:8080 and the SSO round-trip.
- [ ] **Single-tenant lockdown** (optional): Entra authority hard-coded to `/common/` in `OAuth2ClientRegistrationConfig.java:47-49` → accepts any tenant + personal MS accounts. No env var for tenant id; needs a code change to use the Enerkem tenant.
- [ ] **Auto-provisioning** (`OAuth2AuthenticationSuccessHandler.java:115-153`): first-time SSO users each spawn their own org+Administrator+300-user subscription, UNLESS a user with the same email domain already exists (then throws "You must be invited"). For an internal rollout, likely want everyone joining ONE org. Review `createUserFromOAuth`.
- [ ] **No Entra group → Atlas role mapping**; SSO users become org Administrator.
- [ ] **Token-in-URL handoff** (`?token=`) — security-review note (can leak via logs/referrer).
- [ ] Keep the `/source-code` downloadable bundle in sync with each deployment (it must be the actually-deployed modified source).
- [ ] The standalone `frontend/Dockerfile` still uses `npm install --legacy-peer-deps` (drift risk) — consider switching to `npm ci` for consistency (not done; that image isn't used by the single-jar path).

---

## 9. Licensing summary (AGPLv3, NOT legal advice)

Dual-licensed (`LICENSE` AGPLv3 / `COMMERCIAL_LICENSE.MD`) — cannot mix rights. We chose **AGPLv3**.
- **MAY:** run for any purpose, modify freely (incl. removing the SSO gate — legal under AGPL; the commercial license's anti-circumvention only binds commercial licensees), distribute under AGPLv3.
- **MUST:** AGPL §13 network-use source disclosure (every user offered the complete corresponding source of the modified version → satisfied by `/source-code`), keep AGPLv3, preserve notices, no warranty.
- **Commercial-only (NOT used here):** white-labeling/branding (`BRAND_CONFIG`/`LOGO_PATHS`/`CUSTOM_COLORS`), and SSO-as-shipped behind `LICENSE_KEY` (we removed that gate instead of buying a license).

---

## 9. Fork hygiene + Azure DevOps release pipeline (2026-08-28)

### Repository is now a proper downstream fork

`origin` was pointing at `Grashjs/cmms` itself — there was no separation between
our code and upstream's, and every Enerkem change was uncommitted working-tree
state (0 commits ahead, 507 behind). Now:

- `origin` = Azure DevOps `EnerkemIT/New Services Implementations/cmms`
- `upstream` = `github.com/Grashjs/cmms`, fetch only, push URL literally `DISABLED`
- `main` = the Enerkem line and the Azure DevOps default branch
- upstream is **not** mirrored to a local branch; it lives as the
  `upstream/main` ref plus tags

All prior work is committed as 8 themed commits on top of `51341f8e` (build,
SSO, licensing, an OAuth2 signup bugfix, AGPL §13, frontend deps, IDE, docs) so
that future merge conflicts are attributable to a specific concern.

**Merge policy (now in CLAUDE.md): release tags only, one tag at a time,
oldest first, always merge and never rebase.** `upstream/main` is their
unreleased line and sits 279 commits past their last tag.

Pending review, not started: `v1.7.0` (+16 commits from our base) then `v1.8.0`
(+228). Worst expected conflict is `frontend/package*.json` — upstream has since
removed axios, firebase and jsonwebtoken while our §0 refresh bumped axios to
^1.7.9, so that commit is disposable and should be re-derived, not merged.

### `azure-pipelines.yml` (new)

Triggered **only** by `release/*` tags (branches excluded, `pr: none`); the
version is the part after the slash and becomes the build number and image tag.

One job, three phases: `docker build` of `api/Dockerfile` from the repo root
(the existing multi-stage file already does source-bundle → whole Maven reactor
incl. the CRA build → `amazoncorretto:17-alpine` runtime, Java 17 throughout);
a smoke test against a scratch Postgres; then push to ACR. Build and verify
share one job deliberately — the image only exists locally between them, and
pushing an unverified image just to move it between agents defeats the point.

The smoke test is the reason this pipeline exists: it asserts the container
actually **serves the SPA** — shell at `/`, `asset-manifest.json`, the main JS
bundle it names, a deep link forwarding through `SpaForwardController`, and a
non-empty `/source-code/download`. A jar that boots with an empty
`classpath:/static` passes a health check and fails every one of these; that
exact bug already bit us once (§3, reactor ordering).

### `api/Dockerfile` — new build args

`REACT_APP_API_URL/ENABLE_SSO/OAUTH2_PROVIDER` are compiled into the CRA bundle,
and the Dockerfile had no way to receive them, so any image it produced baked
the pom default `http://localhost:8080`. Added `FRONTEND_API_URL`,
`FRONTEND_ENABLE_SSO`, `FRONTEND_OAUTH2_PROVIDER` build args (defaults unchanged
from the pom) which the pipeline feeds from variables.

**Consequence: the image is environment-specific and cannot be promoted between
environments with different URLs.** `frontend/src/config.ts` already reads
`window.__RUNTIME_CONFIG__` from `/runtime-env.js` as a fallback, so a
config-agnostic image is possible later by building with those vars empty and
serving a generated `runtime-env.js`. Not done — build-time env wins in
`getRuntimeValue`, and `runtime-env.js` does not currently exist.

### `REQUIREMENTS.md` (new)

Every pipeline and runtime variable, in two groups (`atlas-cmms-build`,
`atlas-cmms-secrets`), with the required-to-boot set called out: `DB_URL`
(host:port/db, no jdbc prefix), `DB_USER`, `DB_PWD`, `JWT_SECRET_KEY`,
`PUBLIC_API_URL`, `PUBLIC_FRONT_URL`, `MAIL_RECIPIENTS`, `STORAGE_TYPE`.

### Deploy stage → `cmms-prod`

Modelled on the existing `it-poet` pipeline (`../itsheets/azure-pipelines-1.yml`),
reusing the same shared service connections: registry
`3531bbd9-3f78-490d-a3f2-263804a11891`, subscription
`9ce67bd0-4ae6-490b-9976-a14930a3cb1b`, registry host `enerkem.azurecr.io`.

Images publish as `enerkem.azurecr.io/cmms:prod` (the moving tag the web app
pulls) plus an immutable `cmms:<version>` per release, so a rollback repoints
the web app at a specific build instead of rebuilding from a tag.

`AzureWebAppContainer@1` deploys to **`cmms-prod`** and rewrites the app
settings from the variable groups on **every** deploy, so the web app cannot
drift from what the groups say. `WEBSITES_PORT=8080` is set because Web App for
Containers otherwise probes the wrong port and serves 504.

Two gotchas that are documented in REQUIREMENTS.md and easy to get wrong:

- Azure DevOps leaves an **undefined** `$(FOO)` as the literal string `$(FOO)`.
  A missing variable therefore does not fail the build — it writes garbage into
  the app setting. Every one of the 29 referenced variables must exist in a
  group, blank if unused.
- `AzureWebAppContainer@1` returns as soon as the platform accepts the image,
  and a container that fails to start leaves the *previous* one serving. A
  post-deploy step therefore polls `PUBLIC_API_URL` for the SPA shell for up to
  10 minutes and fails the run if it never appears.

### Release tags must carry the upstream release number

Constraint added 2026-08-28. Our tags are
`release/<upstream release>-enerkem.<n>`, e.g. `release/1.6.0-enerkem.1`. The
counter is our own release number on that upstream base and resets to 1 after
each upstream merge. The whole string becomes the build number and the
immutable image tag.

Enforced by the pipeline's first step, which rejects `release/1.6.0` (no
counter), `release/v1.6.0-enerkem.1` (`v` prefix) and — the useful case —
`release/1.7.0-enerkem.1` while upstream v1.7.0 is not actually merged.

The upstream half is checked against the new repo-root file
**`UPSTREAM_VERSION`** (currently `1.6.0`), which must be bumped **inside** each
upstream release merge, not as a follow-up commit. It is a file rather than a
`git describe` because upstream's `v*` tags are deliberately not mirrored into
this repo: a tag newer than our merge base would drag its entire unreleased
history in with it. If the pipeline rejects a tag because the file disagrees,
the fix is to merge the upstream release, never to edit the file.

### Open

- Access to `origin` switched from SSH to HTTPS (`git remote set-url`) because
  the only local key, `~/.ssh/id_rsa` (RSA, 2021), is not registered with Azure
  DevOps. Auth now goes through Git Credential Manager with a PAT.
- No approval gate on the Deploy stage — it runs automatically after Release.
  Converting `DeployWebApp` to a `deployment` job with an `environment` would
  add one.
- The image is environment-specific (see the Dockerfile build args above), so
  `cmms:prod` cannot be promoted to another environment with a different URL.

---

## 10. Azure Blob storage backend (2026-08-28)

`STORAGE_TYPE=azure` is now a real backend. Added because the original plan of
pointing `MINIO_*` at a blob account cannot work: `MinioService` uses the MinIO
Java SDK, which speaks the S3 API, and Azure Blob has no S3-compatible
endpoint.

`AzureBlobService` (new file) implements the 7-method `StorageService`
interface. Two credential modes, chosen by whether an account key is set:

- **blank key → managed identity.** `DefaultAzureCredential`, signing *user
  delegation* SAS. Preferred: no stored secret. The identity needs *Storage
  Blob Data Contributor* and *Storage Blob Delegator* on the account.
- **key set → shared key**, signing service SAS.

Delegation keys are cached (12 h TTL, 30 min refresh margin) because obtaining
one is a network round trip and `FileMapper` signs every file of every listing
individually. For the same reason `generateSignedUrl` deliberately does **not**
check blob existence — a HEAD per file would multiply every page load by the
number of attachments. `MinioService` behaves the same way; `GCPService` does
check, and pays for it.

Cost of the change, and why it was cheap: the two files needing edits,
`StorageType` (enum) and `StorageServiceFactory` (switch), have **zero**
upstream churn, so this is effectively conflict-free on future merges. New
config block `storage.azure.*` in `application.yml`; `com.azure:azure-storage-blob`
12.25.1 and `com.azure:azure-identity` 1.11.4 pinned explicitly in `api/pom.xml`,
matching how minio and google-cloud-storage are already declared. Verified with
`mvnw -DskipTests -DskipFrontend=true compile` → BUILD SUCCESS.

**Network requirement, unchanged by the backend choice:** `FileMapper` hands
signed URLs to the browser and the API never proxies file bytes, so the store
must be reachable from end-user browsers, not just from the web app. A private
endpoint is fine if users can resolve and reach it. Signatures are host-bound —
the hostname the server signs with is the hostname the browser must use.

---

## 11. OpenTofu infrastructure, test + prod (2026-08-28)

Two environments, both in the shared `New-Implementations` RG of the
`Enterprise` subscription. `test/*` tags deploy `cmms-test` straight through;
`release/*` tags deploy `cmms-prod` behind an approval gate on the `cmms-prod`
Azure DevOps environment.

**OpenTofu now owns the application settings.** They live in
`infra/envs/<env>/main.tf`, not in the pipeline and not in the portal — the two
were previously going to fight over the same 33 app settings on every deploy.
The pipeline's deploy step is now `tofu apply` + `az webapp restart`.

### Layout

```
infra/bootstrap/      enkmtfstate001 state account. Run once, by hand.
infra/modules/cmms/   one module, both environments
infra/envs/{test,prod}/
```

Per env it creates only `cmms-*`: user-assigned identity, App Service Plan
(B2 test / P1v3 prod), Linux web app, storage account + `atlas-files`
container, Key Vault, four role assignments, diagnostic setting. The RG, the
`enerkem` ACR, the Log Analytics workspace, the DB server and the VNet subnets
are data sources or passed-in ids, so `tofu destroy` cannot reach another
team's app in that shared RG.

Validated: `tofu validate` clean on all three configs, `tofu fmt` clean.

### Two things that were caught by validating

**Dependency cycle → user-assigned identity.** The first draft used a
system-assigned identity. `tofu validate` rejected it outright: the role
assignments need `identity[0].principal_id`, so they can only exist after the
web app, but the app needs AcrPull to pull its first image and Key Vault access
to resolve its first secret reference. A separate `id-cmms-<env>` identity lets
every role land before the app is created, so a cold apply yields a working app
instead of one needing a manual restart. Requires
`key_vault_reference_identity_id` and
`container_registry_managed_identity_client_id` to be set explicitly, or the
platform falls back to the absent system-assigned identity.

**Secrets never touch state.** Tofu creates the vaults empty and writes app
settings containing literal `@Microsoft.KeyVault(VaultName=…;SecretName=…)`
strings. It never reads a value, so nothing sensitive reaches the state file or
the pipeline. Cost: the four secrets must be seeded by hand after the first
apply and before the first deploy, or the container will not start.

### OPEN, BLOCKING: which database, and the network path to it

The plan was to reuse `db-cancen-it-poet-test` with new `atlasprod` /
`atlastest` databases. That server:

- has `publicNetworkAccess: Disabled`
- is **VNet-injected** into `New-Implementations-vnet` (**canadacentral**),
  whose only subnet is a /24 already delegated to
  `Microsoft.DBforPostgreSQL/flexibleServers` — no room for an App Service
  subnet, and being VNet-injected it cannot take a private endpoint either

Every existing App Service integration subnet is a /28 in `VNET-CanEast-Tier1`
(**canadaeast**, RG `RG-CanEast-Tier1`) — `Dev-Tier1-PMOProject`,
`Prod-Tier1-PMDMS`, `Prod-Tier1-ITStatusDashboard` and friends. Regional VNet
integration requires the subnet's VNet to be in the same region as the plan, so
a canadaeast web app cannot integrate into the canadacentral VNet.

The other server, `db-caneast-django-pmo-test`, is already reachable from
`VNET-CanEast-Tier1/Prod-Tier1-BackEnd` via private endpoints.

Options: (a) use `db-caneast-django-pmo-test` — by far the easiest, same region,
path already exists; (b) peer the two VNets and link the private DNS zone;
(c) move the app to canadacentral and widen `New-Implementations-vnet`.

`infra/envs/*/main.tf` currently points at `db-cancen-it-poet-test` per the
original instruction. **Resolve this before creating the databases.** Free /28s
in the canadaeast VNet look like `10.225.5.48/28` and `10.225.5.64/28`.

### Other prerequisites

`REQUIREMENTS.md` has the full list and ordering. Highlights: the SPN needs
**User Access Administrator** (Contributor cannot grant the four role
assignments) plus Storage Blob Data Contributor on the state account; the
`atlas-cmms-build` group drops to six non-secret variables; the old
`atlas-cmms-secrets` group is retired in favour of Key Vault;
`oauth2_client_id` is a `REPLACE-WITH-…` placeholder in both env files.

> ⚠️ **The role requirement above no longer applies to the pipeline**, as of
> §12.1: it applies no infrastructure and needs only Website Contributor.
> Contributor and User Access Administrator moved to whoever runs `tofu apply`
> by hand. The `oauth2_client_id` placeholder is still accurate.

### §11 database question — RESOLVED (2026-08-28), then CORRECTED in §12.4

> ⚠️ **Superseded.** The paragraph below is wrong on two counts, corrected
> 2026-09-10: `10.225.1.107` is `db-caneast-django-pmo-test`, a canadacentral
> *test* server, and `itbudget` does not use it — it uses `10.225.1.104`
> (`db-caneast-pmdms`). Production now uses `db-caneast-pmdms` too, database and
> role both `atlas`. Test legitimately stays on `10.225.1.107`. See §12.4.

Use the shared PostgreSQL server at **`10.225.1.107`**, the private-endpoint
address in `VNET-CanEast-Tier1/Prod-Tier1-BackEnd`. Same server, same address,
as the budget app (`itbudget` runs `jdbc:postgresql://10.225.1.107:5432/budget`).

That settles the region problem: the database is reachable from canadaeast, so
the web apps can use ordinary regional VNet integration into a subnet in
`VNET-CanEast-Tier1`. `db-cancen-it-poet-test` in canadacentral is not used.

Databases and roles exist already — `atlastest`/`atlastest` and
`atlasprod`/`atlasprod`, user name matching database name in both cases.

Addressed by **IP, not name**, matching the other apps on this server. Safe
because pgJDBC defaults to `sslmode=prefer`: the connection is still encrypted
and no certificate hostname check happens. Anyone adding `sslmode=verify-full`
must move to the private DNS name first, or every connection will fail.

Renamed the module input `db_fqdn` → `db_host` accordingly.

Still outstanding: the two `/28` subnets in `RG-CanEast-Tier1`, delegated to
`Microsoft.Web/serverFarms`. `10.225.5.48/28` and `10.225.5.64/28` are free.
The reference implementation is `itbudget`, which integrates into
`Dev-Tier1-PMOProject` with `vnetRouteAll` enabled — the same two settings our
module applies.

---

## 12. Pipeline reduced to build-and-restart; prod DB and container SSH (2026-09-10)

Four related changes, all driven by decisions taken this session.

### 12.1 OpenTofu is out of the pipeline

**Decision (owner):** *"Do not run opentofu on the pipeline, exclude it for
now. We will do it in a later release. The pipeline should avoid creating any
infrastructure, all the infrastructure will be there."*

`.azure/steps-deploy.yml` lost the OpenTofu install, `tofu plan` and
`tofu apply` steps. What is left per environment is: preflight → restart →
verify SPA → dump the container log. `tofuVersion` is gone from
`azure-pipelines.yml`, and `VNET_SUBNET_ID_TEST` / `VNET_SUBNET_ID_PROD` are no
longer pipeline variables — only Tofu consumed them, so they move to whoever
applies by hand as `TF_VAR_vnet_integration_subnet_id`.

Consequence worth remembering: the service principal no longer needs
Contributor or **User Access Administrator** on `New-Implementations` — the
item flagged as "most likely to need a request". It needs Website Contributor.
Those roles move to the person running `tofu apply`, who additionally needs
Reader on `RG-CanEast-PMDMS` and `RG-CanEast-Tier1`.

**The `infra/` config is now out of step with reality** and must not be applied
as-is: it describes `cmms-test` / `cmms-prod` on dedicated plans, while
production is the hand-made `cmms`. Applying it would create a second app.
Reconciling — import `cmms`, or let Tofu own a fresh app and retire `cmms` — is
the first decision when the OpenTofu path resumes.

### 12.2 The pipeline now targets the real web app, and preflights it

`cmms` (New-Implementations, canadaeast, created 2026-09-10 21:25) is a **site
containers** app: `linuxFxVersion` is the literal string `sitecontainers` and
the image lives on the main site container instead —
`enerkem.azurecr.io/cmms:latest`, target port 8080, pulled with the
user-assigned identity `ua-id-9ca4` (`dbb349c1-…`). It sits on the shared
`ASP-dev-pmo-project-tracking-a972` plan (B3 Basic).

So the deploy template:

- reads the target app name from the environment file (originally variable-group
  values `WEBAPP_NAME_TEST`/`WEBAPP_NAME_PROD`; see §12.8) rather
  than hardcoding `cmms-test`/`cmms-prod`, because the apps are hand-made and
  have already been renamed once;
- resolves the running image from the **main site container** when
  `linuxFxVersion == "sitecontainers"`, and from `linuxFxVersion` otherwise;
- **fails unless that image is one of the three tags the run just pushed.**
  Without this the release is a silent no-op waiting to happen: `az webapp
  restart` succeeds against an app pinned to an older tag or digest, re-pulls
  the *old* image, and the SPA poll then passes. Green release, nothing
  deployed.

A bug caught while writing it: the preflight first compared against
`$(targetEnv)` and `$(releaseVersion)`. Those are set with `task.setvariable`
in the **Build** stage, and `task.setvariable` is job-scoped — they arrive
empty in the deploy stages. Both are now re-derived from `$(Build.SourceBranch)`
inside the step, which every stage can see.

### 12.3 `:latest` is now pushed, and it is production's tag

**Decision (owner):** tag the image `latest` on every push to the registry,
replacing the existing one.

The publish step pushes `:latest` alongside `:<env>` and `:<version>`. This is
not cosmetic — `cmms` pulls `:latest`, so **`:latest` is the tag that actually
deploys.**

⚠️ Which means a `test/…` tag moves the image production will pull on its next
restart. There is no test app today; while `WEBAPP_NAME_TEST` also names
`cmms`, a test release *is* a production release. The fix is a separate test
app tracking `:test`, at which point `:latest` can go back to being a marker.

### 12.4 Production database: `db-caneast-pmdms`, referenced not managed

**Decision (owner):** *"The database server for the production release is
db-caneast-pmdms.postgres.database.azure.com, already existing, can be
referenced in opentofu but the resource should not be touched."*

Both environments previously pointed at `10.225.1.107`. Reading the live
environment showed what that actually is, and it is not what §11 assumed:

| Private endpoint | IP | Server |
|---|---|---|
| `DevPostgresDB` | `10.225.1.107` | `db-caneast-django-pmo-test` |
| `PrivateEndpointPostgreSQL` | `10.225.1.100` | `db-caneast-django-pmo-test` |
| `PMDMSPrivateEndpointPostgreSQL` | **`10.225.1.104`** | **`db-caneast-pmdms`** |

So §11's claim that `itbudget` uses `10.225.1.107` was wrong: `itbudget`'s
`DB_URL` is `jdbc:postgresql://10.225.1.104:5432/budget` — `db-caneast-pmdms`,
the same server production now uses. `10.225.1.107` is a *test* server
(`db-caneast-django-pmo-test`, canadacentral). Test still points there.

`infra/envs/prod/main.tf` now references the server through two data sources:

```hcl
data "azurerm_postgresql_flexible_server" "prod_db" {      # identity
  name                = "db-caneast-pmdms"
  resource_group_name = "RG-CanEast-PMDMS"
}
data "azurerm_private_endpoint_connection" "prod_db" {     # address
  name                = "PMDMSPrivateEndpointPostgreSQL"
  resource_group_name = "RG-CanEast-PMDMS"
}
```

`db_host` is read from the second, so the address is never hardcoded and
`tofu destroy` cannot reach the server. Cost: applying prod needs **Reader on
`RG-CanEast-PMDMS`**.

**Why the IP and not the FQDN the owner gave.** `db-caneast-pmdms` has
`publicNetworkAccess: Disabled`, and there is **no
`privatelink.postgres.database.azure.com` private DNS zone** anywhere in the
subscription — the only postgres private zone is
`db-cancen-it-poet-test.private.…`, linked to a different VNet.
`VNET-CanEast-Tier1` uses the corporate DNS servers `10.250.0.11/12`. So
`db-caneast-pmdms.postgres.database.azure.com` resolves, inside the VNet
exactly as outside, through the privatelink CNAME to **52.229.73.241** — the
server's public address, which refuses the connection. Verified by `nslookup`.
`prod-pmdms` (`POSTGRES_HOST = 10.225.1.104`) and `itbudget` both use the
literal IP for this reason.

The FQDN is recorded in the config as
`data.azurerm_postgresql_flexible_server.prod_db.fqdn` and exposed as an
output, and the comment says exactly what to change if a private DNS zone is
ever linked: switch `db_host` to that attribute and drop the private endpoint
data source.

`tofu validate` clean on both envs, `tofu fmt` clean.

### 12.5 SSH into the container, and a log file

**Decision (owner):** mirror `../budget`'s sshd setup so the Azure SSH tool can
attach and read logs, with the log at `/home/cmms/atlas.log`.

`../budget/Dockerfile` + `container/sshd_config` + `container/startup.sh` were
the reference. Ported to `api/Dockerfile` and two new files,
`api/container/sshd_config` and `api/container/startup.sh`:

- **The runtime base image changed** from `amazoncorretto:17-alpine` to
  `eclipse-temurin:17-jre-noble`. Budget's setup is apt/`openssh-server` on
  Ubuntu; Alpine's musl openssh is not the same thing, and matching budget
  exactly was the instruction. Still Java 17 — newer JDKs break Lombok here.
- sshd on **2222**, `root`/`Docker!`, from the same `sshd_config` budget uses.
  Both values are fixed by App Service, not choices. Not internet-reachable:
  the only route in is the authenticated SCM tunnel.
- Non-root `cmms` user with passwordless sudo, mirroring budget's `budget`.
- `startup.sh` starts sshd in the background, then runs the app in the
  foreground **teed to `$LOG_FILE`** (default `/home/cmms/atlas.log`). stdout
  is untouched, so `az webapp log tail` and Log Analytics keep working. No
  nginx: one jar serves API and SPA on 8080.
- `ENTRYPOINT` is now `sh /app/startup.sh` instead of a bare `java -jar`.

`/home` is not persisted while `WEBSITES_ENABLE_APP_SERVICE_STORAGE` is
`false`, so the file holds only the current container's output — usually what
you want when diagnosing a failed start.

Verified locally: the runtime stage builds; `sshd -T` reports `port 2222`,
`permitrootlogin yes`, `passwordauthentication yes`; `sshd -D -e` binds
`0.0.0.0:2222`; and a deliberately-corrupt jar produced
`Error: Invalid or corrupt jarfile` in `/home/cmms/atlas.log`, proving the tee.
OpenSSH is 9.6p1 on noble and accepts budget's cipher/MAC list unchanged.

### 12.6 What `cmms` still needs before a container can boot

Read from Azure this session. The app is Running but:

- **App settings are just `WEBSITES_ENABLE_APP_SERVICE_STORAGE=false`.** Eight
  of the required variables have no default in `application.yml` (`DB_URL`,
  `DB_USER`, `DB_PWD`, `JWT_SECRET_KEY`, `PUBLIC_API_URL`, `PUBLIC_FRONT_URL`,
  `MAIL_RECIPIENTS`, `STORAGE_TYPE`), so the app exits at startup. Full list in
  REQUIREMENTS.md §7.
- **No VNet integration** (`virtualNetworkSubnetId` is null), so `10.225.1.104`
  is unreachable. This is the first thing to fix.
- **`keyVaultReferenceIdentity` is `SystemAssigned`, but there is no
  system-assigned identity** — only user-assigned `ua-id-9ca4`. Every Key Vault
  reference will fail to resolve, and an unresolvable reference stops the
  container from starting. Point it at the user-assigned identity.
- `atlas` database and its role still to be created on `db-caneast-pmdms`.
- Plan is shared B3 Basic, not the dedicated P1v3 the Tofu config specifies.

### 12.7 Production database renamed to `atlas`, prod URL pinned (2026-09-10)

**Decision (owner):** the production database is `atlas`, not `atlasprod`, and
the production URLs are `https://cmms.enerkem.com`.

- `infra/envs/prod/main.tf`: `db_name = "atlas"`.
- `variable "public_url"` now has `default = "https://cmms.enerkem.com"`.
  It previously had no default because the pipeline supplied
  `TF_VAR_public_url`; with OpenTofu out of the pipeline (§12.1) a manual
  `tofu apply` had nothing to fall back on, and the intended URL lived only in
  an Azure DevOps variable. It stays overridable.
- The owner made the matching edits in `prod.env`: `DB_URL=10.225.1.104/atlas`
  (IP, per §12.4), `PUBLIC_API_URL`/`PUBLIC_FRONT_URL`/`API_URL`/
  `REACT_APP_API_URL` all `https://cmms.enerkem.com` — which also resolves the
  `atlas.enerkem.com` vs `cmms.enerkem.com` mismatch flagged earlier — and
  `STORAGE_TYPE=azure`.

The role was renamed in the same breath, on the owner's follow-up: `db_user`
is now `atlas` too, so `main.tf` and `prod.env` agree. The old `atlasprod`
naming (user matching database, per §11) is gone from production; test still
uses `atlastest`/`atlastest`.

**One thing this leaves open.**

1. **`cmms.enerkem.com` does not exist yet.** Verified this session:
   `nslookup cmms.enerkem.com` returns NXDOMAIN, and `cmms`'s only bound
   hostnames are `cmms-cyhug8h6a8fphdd7.canadaeast-01.azurewebsites.net` and
   its `.scm` twin. A DNS record, a custom hostname binding and a certificate
   are all still needed. The module creates no hostname binding, so this is
   manual work — and it must be in place *before* the first image build, since
   the URL is compiled into the SPA bundle.

Also unresolved from the owner's `prod.env` edits, worth a look before release:
`AZURE_STORAGE_ENDPOINT=https://cmms-storage.enerkem.com`. SAS signatures are
host-bound, so that hostname has to actually front the storage account;
Azure Blob custom domains do not serve HTTPS without CDN or Front Door in
front. Leaving the value blank uses
`https://<account>.blob.core.windows.net`, which works as-is.

### Files touched

| File | Change |
|---|---|
| `azure-pipelines.yml` | no `tofuVersion`; `:latest` pushed; app names from variables; comments |
| `.azure/steps-deploy.yml` | rewritten: no OpenTofu; site-container-aware preflight; log dump |
| `api/Dockerfile` | runtime stage → temurin noble + sshd + startup.sh |
| `api/container/sshd_config` | new; copy of budget's |
| `api/container/startup.sh` | new; sshd + app teed to `$LOG_FILE` |
| `infra/envs/prod/main.tf` | prod DB via data sources on `db-caneast-pmdms`; `db_server` output; `db_name = atlas`; `public_url` defaults to `https://cmms.enerkem.com` |
| `REQUIREMENTS.md` | variables, roles, two DB servers, new §7 for `cmms`; `atlas` db name, role-name and DNS warnings |
| `infra/README.md` | not-applied-by-CI warning; the two DB servers; `atlas` db name; DNS prerequisite |
| `CLAUDE.md` | §2b rewritten; runtime image note in §3 |

### 12.8 Pipeline settings moved from a variable group into committed files (2026-09-11)

**Owner's ask:** the list of pipeline variables, and whether a file could be
used instead, taking the values from `prod.env`.

It can, and it is better. Two new committed files replace the
`atlas-cmms-build` variable group entirely:

```
.azure/env/prod.env     read on a release/... tag
.azure/env/test.env     read on a test/... tag
```

Five keys each, all non-secret: `PUBLIC_URL`, `ENABLE_SSO`, `OAUTH2_PROVIDER`,
`WEBAPP_NAME`, `WEBAPP_RESOURCE_GROUP`. The Build job sources its
environment's file after validating the tag; the deploy template sources the
same file again in its own job. **That re-read is deliberate, not
duplication:** `task.setvariable` is job-scoped, so nothing the Build stage set
is visible in the deploy stage — the bug from §12.2. Reading the file is how
both jobs see the same values.

**Why not upload the root `prod.env` as an Azure DevOps secure file**, which
would have been the literal reading of "use the values in prod.env": the
pipeline has no use for `DB_PWD`, `JWT_SECRET_KEY` or `OAUTH2_CLIENT_SECRET`.
It no longer writes application settings and no longer applies infrastructure,
so all it needs are the four values baked into the SPA bundle plus the name of
the app to restart. Handing a build agent secrets it does not need only widens
where they can leak. The root `prod.env` stays gitignored and out of the Docker
context; `.azure/env/*.env` are committed on purpose. They overlap on the URL
and the two SSO flags — **change one, change the other.**

Gains beyond having the values in git with history:

- **Undefined values now fail the run.** Azure DevOps leaves an undefined
  `$(FOO)` as the literal string `$(FOO)`, which is why the old resolve step
  needed a prefix-stripping guard to notice a missing variable at all. All five
  keys are now checked for emptiness by name, and `PUBLIC_URL` must be
  `https://` with no trailing slash.
- **One less thing to set up.** The variable group never existed in Azure
  DevOps, so this removes an item from the blocking list instead of adding one.
  What remains there is the `cmms-prod` environment and its approval check.
- The deploy template lost its `webAppName` and `publicUrl` parameters, so the
  stages now carry nothing environment-specific.

Verified by running the exact parse logic locally against both files, including
a negative test that a trailing slash is rejected. Both YAML files still parse.

Also corrected two stale comments found while editing: the pipeline header
still named the old `WEBAPP_NAME_*` variables, and the build step still
described stage 3 as `amazoncorretto:17-alpine` rather than the temurin-noble
runtime from §12.5.

### 12.9 Secret storage settled: Key Vault with unversioned references (2026-09-11)

**Owner's question:** with secrets out of the pipeline, where do they live, and
how are they managed day to day?

Answer, now written up as `REQUIREMENTS.md` §2: a per-environment Key Vault
(`enkm-cmms-prod` / `enkm-cmms-test`), with application settings holding
**unversioned** `@Microsoft.KeyVault(VaultName=…;SecretName=…)` references that
App Service resolves at container start as the app's managed identity. This is
the design the OpenTofu module already encodes, so doing it by hand now with the
same vault names keeps a future `tofu apply` able to adopt it rather than
creating a second vault.

Unversioned is the part that answers "manage them": rotation is
`az keyvault secret set` plus `az webapp restart` — no redeploy, no pipeline
run. Versions give history and rollback, and Key Vault logs every read.

**Three things this turned up.**

1. **`REQUIREMENTS.md` §2 contained an instruction that cannot be followed.** It
   said to set all four secrets "blank, not absent", with
   `az keyvault secret set --value ''`. Key Vault rejects an empty secret value,
   so that command fails. Corrected: `smtp-password` is simply **omitted** while
   mail is off, and the `SMTP_PWD` app setting left unset — `application.yml`
   declares `${SMTP_PWD:}`, which defaults to empty. Only three secrets are
   actually needed.
2. **Which secrets are load-bearing, checked against `application.yml`.**
   `DB_PWD` (`${DB_PWD}`) and `JWT_SECRET_KEY` (`${JWT_SECRET_KEY}`) have **no
   defaults**, so the app cannot boot without them. `OAUTH2_CLIENT_SECRET` is
   read straight from the environment in `OAuth2ClientRegistrationConfig`, so a
   missing value fails SSO at login rather than at boot. `SMTP_PWD` is optional.
3. **No Key Vault exists for CMMS.** Verified 2026-09-11: the subscription has
   `enkm-ecc-vault-dev` and `enkmGeneral`, both other people's. The prod vault
   has to be created.

§2 now carries the full runnable sequence — create the vault with RBAC and purge
protection, grant *Key Vault Secrets Officer* to the operator and *Key Vault
Secrets User* to principal `11b7cf2e-710f-4401-987d-4f98e466486b` (`ua-id-9ca4`),
set the three secrets, **fix `keyVaultReferenceIdentity`**, then set the three
referencing app settings — plus a management table and a note on why not to copy
`itbudget`, which keeps its `DB_PASSWORD` as a literal app setting.

The `keyVaultReferenceIdentity` fix is step 4 and the one that actually blocks:
it is still `SystemAssigned` on an app whose only identity is user-assigned, so
every reference would fail to resolve and stop the container. It was already in
the blocking list; §2 now has the command.

### 12.10 OpenTofu parked; pipeline rebuilt as production-only (2026-09-11)

**Owner's decision:** *"we are not using opentofu yet… today we have
implemented the infrastructure by hand: the webapp, storage container, network,
etc; are all set and ready to go for the deployment. This pipeline will ONLY
create and deploy the container in PRODUCTION only… Same as ../itsheets or
../budgets… don't count on a working tofu."*

**OpenTofu is parked.** `infra/` keeps its files but carries a PARKED banner and
must not be applied: it describes `cmms-test`/`cmms-prod` on dedicated plans and
its own `cmmsstorageprod001` storage account, so applying it would build a
second, parallel environment beside the hand-built one. Reconciling — import, or
a fresh environment — is the first task whenever it is unparked. `CLAUDE.md` §2b
was rewritten around the hand-built reality, and REQUIREMENTS.md §3 is now
marked reference-only.

**The pipeline was rebuilt in the itsheets/budget shape:** one `release/*`
trigger, `name: $(Date:yyyyMMdd)$(Rev:.rr)`, a single job on `ubuntu-latest`,
`checkout: self`, build, push, then `AzureWebAppContainer@1` onto the existing
app with an `appSettings` list — the same task and the same
settings-not-listed-are-left-alone principle budget relies on to keep its
secrets out of CI. The Test stage, the `cmms-prod` environment gate and
`.azure/steps-deploy.yml` are gone; `.azure/env/test.env` with them.

Two deliberate divergences from itsheets/budget:

1. **Plain `docker build`, not `Docker@2` with `buildAndPush`.** That task
   *ignores* its `arguments` input, which would silently drop the three
   `--build-arg` values and bake `localhost:8080` into the SPA bundle. itsheets
   and budget need no build args, so the trap never bites them.
2. **The smoke test is kept.** Postgres plus the image on the agent, asserting
   the SPA shell, the asset manifest, the main bundle, a deep link and the
   source bundle. This packaging's characteristic failure is a jar that boots
   perfectly and serves an empty `classpath:/static`, which no health check
   sees — and it already caught the `JWT_SECRET_KEY` base64 bug (§12.2).

`.azure/env/prod.env` grew from five keys to the full non-secret set: web app
name and resource group, image repository, the SPA build values, and every
application setting the deploy task pushes (`WEBSITES_PORT`, `DB_URL`,
`DB_USER`, storage account and container, Entra ids, mail flags, `ENABLE_CORS`,
`LOG_FILE`). Secrets stay out of it entirely — they are Key Vault references set
by hand (§12.9) and the pipeline never names them.

**Read from Azure while wiring this up, and both are problems.**

- **Storage account `stgcaneastcmms`** (canadaeast, `New-Implementations`) has
  `publicNetworkAccess: Disabled`, `defaultAction: Deny`, `allowBlobPublicAccess:
  false`, and one approved private endpoint. The container could not be listed
  from outside the network, so the name was guessed as `atlas-files`; the
  owner's `prod.env` later showed it is actually **`cmms`**, now corrected in
  `.azure/env/prod.env`. More importantly the app hands browsers **signed SAS URLs**
  and never proxies file bytes, so uploads will work through the private
  endpoint while every download in the UI fails. Options are in START HERE;
  the parked Tofu config deliberately set `public_network_access_enabled = true`
  for exactly this reason.
- **`AzureWebAppContainer@1` will convert `cmms` off the site-containers
  model** by setting `linuxFxVersion`. Flagged in the YAML with a commented-out
  `az webapp sitecontainers update` alternative rather than silently choosing.

Also corrected three stale claims found while editing: `infra/README.md` still
said "the pipeline runs exactly this" and still told the reader to store a blank
`smtp-password` (impossible — see `bug-028`), and REQUIREMENTS.md §5 still
described the runtime image as `amazoncorretto:17-alpine`.

Validated: `azure-pipelines.yml` parses, one job, 13 steps; every key the YAML
reads is present in `.azure/env/prod.env`, checked by running the pipeline's own
parse logic locally.

### 12.11 Azure DevOps verified; mail relay; Key Vault script (2026-09-11)

The pipeline was created in Azure DevOps and checked with the CLI before its
first run. **It would not have worked.** Four things found, three fixed here.

**1. The service connection ids were from another project.** Service
connections are project-scoped, and the two ids were copied from
`../itsheets` / `../budget`, whose pipelines live elsewhere. Neither resolved
in "New Services Implementations", so the ACR login and the deploy would both
have failed. Corrected against `az devops service-endpoint list`:

| purpose | id | name |
|---|---|---|
| registry | `784814e7-aa27-4bd8-89dd-31cfbfaa46bc` | `DEVOPS - ACR` -> registry `enerkem` |
| subscription | `ca8fb3b0-6089-454b-a98e-03739e391ab1` | `Enterprise (d14f7b8e-...)` |

The project's other docker connection, `Docker Registy connector`, points at
`sjusiccontainerregistry` and is the wrong one.

**2. Two pipelines, same repo, same YAML.** `cmms` (id 41, created 2026-08-28)
and `cmms (42)` (created 2026-09-11). One tag push would have started two runs
racing onto the same web app. Neither had ever run; 42 deleted on the owner's
instruction.

**3. Pipeline 41 was not authorised for the Azure service connection.** That
connection has no "all pipelines" grant, only an explicit allow-list. Added 41.
The registry connection is open to all pipelines, so it needed nothing.

**4. The deploy service principal had no permission to deploy.** Object id
`1b4bea4e-71c0-45c1-8571-671d6b46edd0` held only Key Vault roles on seven
unrelated vaults — nothing at subscription or resource-group scope.
**Website Contributor** granted on `New-Implementations` (assignment
`eb4548e2-9798-4083-b237-879214af66c6`), verified present.

Confirmed healthy without changes: the ACR connection's principal has
**AcrPush** on `enerkem`; the web app identity `ua-id-9ca4` has **AcrPull**
there plus **Storage Blob Data Contributor** and **Storage Blob Delegator** on
`stgcaneastcmms` — the Delegator role being the one that is easy to forget;
Microsoft-hosted agents are working (PMDMS ran successfully the same day).

Worth noting for the future: **Microsoft Graph is blocked by Conditional
Access** in this tenant, so `az ad sp show` and `az role assignment list`'s
name resolution both fail. Role assignments have to be read through
`az rest` against the ARM authorization API, and principals addressed by object
id with `--assignee-object-id` + `--assignee-principal-type`.

### Mail

Owner's decision: the relay is **`smtp.enerkem.com:25`, no authentication, no
password**. Added to `.azure/env/prod.env` as `MAIL_TYPE`, `SMTP_HOST`,
`SMTP_PORT` and `SMTP_FROM`, and forwarded by the pipeline.

`SMTP_AUTH` and `SMTP_STARTTLS` were **inert** when first configured:
`application.yml` hardcoded

```yaml
properties.mail.smtp:
  auth: true
  starttls.enable: true
```

with no env placeholder, so neither name was read by anything. On the owner's
instruction they are now parameterised as `${SMTP_AUTH:true}` and
`${SMTP_STARTTLS:true}` — defaults kept `true`, so a Gmail-style setup is
unaffected — and both are pushed as `false`. That is a two-line edit to an
upstream file; `application.yml` is not on the conflict hot-spot list, so the
merge cost is small.

Note there is a **second, stray `properties.mail.smtp` block indented under
`spring.jpa`** (lines 53-56). It is upstream noise — those keys are handed to
Hibernate and do nothing — and was deliberately left alone.

`SMTP_USER`/`SMTP_PWD` stay unset, so no Key Vault secret is needed for mail.
`ENABLE_EMAIL_NOTIFICATIONS` and `INVITATION_VIA_EMAIL` are both **true** per
the owner's settings; a silently-dropping relay would mean new users never
receive an invitation, so that is the first thing to check if someone cannot
get in.

Also corrected: `SMTP_FROM` **is** read — via `@Value("${spring.mail.from:...}")`
in `EmailService2`, not through `MailProperties` binding. An earlier note in
this session doubted that.

### The storage container is `cmms`, not `atlas-files`

`.azure/env/prod.env` carried `atlas-files`, which was a guess made when the
account's `defaultAction: Deny` blocked listing its containers. The owner's
`prod.env` shows the real name is **`cmms`**. Corrected. The parked OpenTofu
module still says `atlas-files` — one more thing to reconcile when it is
unparked.

### `scripts/setup-keyvault.ps1`

New. Does the whole Key Vault setup from the repo-root `prod.env`: creates the
vault (RBAC, purge protection), grants *Key Vault Secrets Officer* to the
operator and *Key Vault Secrets User* to `ua-id-9ca4`, loads the three secrets,
fixes `keyVaultReferenceIdentity`, sets the referencing app settings, and
reports each reference's resolution status. Idempotent, so re-running it is
also how a rotation is done. Verified with `-WhatIf` against the live
subscription.

Three details it exists to get right:

- **Splits each line on the first `=` only.** Base64 values are `=`-padded, so
  a naive split truncates `jwt-secret-key` and the app dies at startup with
  `Illegal base64 character`.
- **Validates `JWT_SECRET_KEY` as strict base64 decoding to ≥ 32 bytes** before
  writing anything.
- **Retries the first secret write**, because a role assignment made seconds
  earlier may not have reached the Key Vault data plane yet.

A bug in the first version, reported by the owner: the `Invoke-Az` helper was an
advanced function whose parameter was named `$Args` with
`ValueFromRemainingArguments`. PowerShell then tried to bind `-o json` as one of
*its* parameters and failed with "the parameter name 'o' is ambiguous" (it
matches `-OutVariable` and `-OutBuffer`). Fixed by making the helpers simple
functions with no `param()` block, so every token lands in the automatic
`$args` and reaches `az` untouched. Logged as `bug-029`.

### 12.12 First release attempt: the tag trigger never fired (2026-09-13)

`main` was pushed and `release/1.6.0-enerkem.1` tagged at `47845f58`. **No run
was queued by the tag.** The only run on the pipeline, `5971`, was
`reason: manual` against `refs/heads/main`, and it failed at the first step —
correctly, because this pipeline only builds `release/*` tags. That failure was
the guard doing its job, not a defect.

The defect is the trigger. It was written as

```yaml
branches: {exclude: ['*']}
tags:     {include: ['release/*']}
```

A branch filter that excludes everything leaves the CI trigger with nothing to
match on, and the separate `tags` block does not rescue it, so the tag push
queued nothing at all. Rewritten to the form Azure DevOps evaluates reliably:

```yaml
branches:
  include:
    - refs/tags/release/*
```

Ordinary branches still cannot trigger it, because they never match
`refs/tags/*`.

The tag-resolution step's error messages now also distinguish the three ways of
getting this wrong — started on a branch (i.e. someone clicked *Run pipeline*),
a `test/*` tag, or a malformed version — instead of one message that mentioned
test tags when the actual problem was a manual run. Verified by running the
case statement against all four ref shapes.

**Re-tagging is required**, because the tag already exists and points at a
commit whose YAML has the broken trigger. Delete and recreate it on the fix.

### Deployment readiness at this point

Checked live the same day:

| | |
|---|---|
| `origin/main` | `47845f58` — pushed ✅ |
| Vault `enkm-cmms-prod` | exists, with `db-password`, `jwt-secret-key`, `oauth2-client-secret` ✅ |
| *Key Vault Secrets User* for `ua-id-9ca4` | granted ✅ |
| Non-secret app settings on `cmms` | all present ✅ |
| **`DB_PWD` / `JWT_SECRET_KEY` / `OAUTH2_CLIENT_SECRET` app settings** | **missing** ❌ |
| **`keyVaultReferenceIdentity`** | still `SystemAssigned` ❌ |

So the vault half is done but the web app was never wired to it — steps 4 and 5
of `scripts/setup-keyvault.ps1`, which is what `-SkipWebApp` leaves out. Until
those two are fixed the container cannot boot: `DB_PWD` and `JWT_SECRET_KEY`
have no defaults in `application.yml`.

### 12.13 Database grants: `atlas` could not create anything (2026-09-14)

Checked through the IntelliJ datasource *Production CA-CENTRAL*
(`10.225.1.104:5432`, PostgreSQL 16.15, ping 12 ms, SSL on) as `enk_pg_admin`.

**The database was fine, the schema was not.**

| | before | after |
|---|---|---|
| `atlas` database owner | `atlas` ✅ | unchanged |
| `public` schema owner | **`azure_pg_admin`** ❌ | `atlas` |
| `public` ACL | `{azure_pg_admin=UC/azure_pg_admin,=U/azure_pg_admin}` | `{atlas=UC/atlas,=U/atlas}` |
| `atlas` USAGE on public | true (inherited from PUBLIC) | true |
| **`atlas` CREATE on public** | **false** ❌ | **true** |

This is the PostgreSQL 15+ change: `public` no longer grants CREATE to
`PUBLIC`, so an application role that does not own the schema cannot create
anything in it. The app runs Liquibase on every boot with
`ddl-auto: validate`, so the first container start would have failed on
`permission denied for schema public` — a failure that would have looked like
a bad release rather than a missing grant.

Fixed with two statements, on the owner's instruction:

```sql
ALTER SCHEMA public OWNER TO atlas;
GRANT ALL ON SCHEMA public TO atlas;
```

Safe to do in place: the schema held **0 objects**, so there was no existing
object ownership to migrate. `enk_pg_admin` is a member of both `atlas` and
`azure_pg_admin`, which is what made the ownership change possible.

Verified functionally rather than just by reading the ACL — ran
CREATE TABLE / INSERT / CREATE INDEX / ALTER TABLE / DROP TABLE inside
`SET LOCAL ROLE atlas`, all of which succeeded, and confirmed 0 leftover
objects afterwards. The `atlas` role has LOGIN and an unexpired password.

`PUBLIC` keeps its default USAGE on the schema; that is the PostgreSQL default
and was left alone.

**Tooling note:** the `intellij` MCP server fails to connect in this
environment ("SSE error: Unable to connect"), but the `idea` MCP server works
and is what the database tools live on.

