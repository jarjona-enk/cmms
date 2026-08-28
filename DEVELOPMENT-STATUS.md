# Development Status — Atlas CMMS internal build (Entra SSO + single-jar + AGPL)

> Context hand-off for another session. Last updated: 2026-06-18 by jarjona@enerkem.com.
> Project = **Atlas CMMS** (open-source, AGPLv3/commercial dual-licensed).
> Stack: backend Java **Spring Boot** (`api/`), frontend **React/TS** (`frontend/`), `mobile/` (RN, untouched).

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

### Open

- Access to `origin` switched from SSH to HTTPS (`git remote set-url`) because
  the only local key, `~/.ssh/id_rsa` (RSA, 2021), is not registered with Azure
  DevOps. Auth now goes through Git Credential Manager with a PAT.
- No approval gate on the Deploy stage — it runs automatically after Release.
  Converting `DeployWebApp` to a `deployment` job with an `environment` would
  add one.
- The image is environment-specific (see the Dockerfile build args above), so
  `cmms:prod` cannot be promoted to another environment with a different URL.
