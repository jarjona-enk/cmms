# REQUIREMENTS.md — pipeline and deployment configuration

Every setting `azure-pipelines.yml` needs, what to put in each, and which ones
the application refuses to start without.

## How configuration reaches the running app

The pipeline sets the web app's application settings on **every deploy**, from
the variable groups below. That is deliberate: `cmms-prod` cannot drift away
from what the groups say, and the groups are the single source of truth.

⚠️ **Every variable listed here must exist in its group, even when the correct
value is empty.** Azure DevOps leaves an undefined `$(FOO)` as the literal
string `$(FOO)`, so a missing variable does not fail the build — it silently
writes garbage into the app setting. Create them all; leave the unused ones
blank.

Create both groups under **Pipelines → Library** and link them to the pipeline
before the first run.

| group | contents | secret |
|---|---|---|
| `atlas-cmms-build` | everything non-sensitive | no |
| `atlas-cmms-secrets` | credentials and keys | yes — mark each as secret, or link the group to Azure Key Vault |

### Not variables

These are pipeline constants in `azure-pipelines.yml`, matching the existing
`it-poet` pipeline. Change them in the file, not in a group.

| Constant | Value |
|---|---|
| Registry service connection | `3531bbd9-3f78-490d-a3f2-263804a11891` |
| Azure subscription service connection | `9ce67bd0-4ae6-490b-9976-a14930a3cb1b` |
| Registry | `enerkem.azurecr.io` |
| Image | `cmms`, tag `prod` (plus an immutable `<version>` tag per release) |
| Web app | `cmms-prod` |

---

## 1. Group `atlas-cmms-build`

### Baked into the SPA at build time

⚠️ These three are compiled into the JavaScript bundle by Create React App and
**cannot be changed at container runtime**. The published image is therefore
specific to the environment named by `PUBLIC_API_URL`, and changing any of them
requires a new build and a new release tag.

| Variable | Example | What to put in it |
|---|---|---|
| `PUBLIC_API_URL` | `https://cmms-prod.azurewebsites.net` | Public base URL of the deployment, **no trailing slash**. The SPA calls the API here, Entra redirects back to `${PUBLIC_API_URL}/oauth2/callback/microsoft` (must match the app registration exactly), and the pipeline's post-deploy check polls it. Same host as the UI, since one jar serves both. |
| `ENABLE_SSO` | `true` | Shows the "Continue with SSO" button and enables the OAuth2 flow. Also passed at runtime, where it gates the backend half. |
| `OAUTH2_PROVIDER` | `microsoft` | `microsoft` for Entra, `google` for Google. |

### Required at runtime — the app will not start without these

`application.yml` gives them no default, so Spring fails placeholder resolution
at startup and the container exits.

| Variable | Example | What to put in it |
|---|---|---|
| `DB_URL` | `atlas-db.postgres.database.azure.com:5432/atlas` | **Host:port/database only.** `application.yml` adds the `jdbc:postgresql://` prefix; including it yourself produces a malformed URL. |
| `DB_USER` | `atlas` | Needs DDL rights — Liquibase runs the changelog on every boot and JPA validates the schema afterwards. |
| `PUBLIC_FRONT_URL` | `https://cmms-prod.azurewebsites.net` | Where the OAuth2 success handler sends the browser (`${PUBLIC_FRONT_URL}/oauth2/success?token=…`). Same host as the API here. |
| `MAIL_RECIPIENTS` | `cmms-admins@enerkem.com` | Comma-separated addresses for system notifications. Must be set **even when email is disabled** — it has no default. |
| `STORAGE_TYPE` | `minio` | `minio` or `gcp`. Selects the file-attachment backend. |

`DB_PWD` and `JWT_SECRET_KEY` are also required — they live in the secrets group.

### Mail server

| Variable | Suggested | What to put in it |
|---|---|---|
| `MAIL_TYPE` | `SMTP` | `SMTP` or `SENDGRID`. |
| `SMTP_HOST` | `smtp.office365.com` | SMTP server hostname. |
| `SMTP_PORT` | `587` | 587 for STARTTLS, which is how the app is configured. |
| `SMTP_USER` | | Account used to authenticate. |
| `SMTP_FROM` | | Envelope From address. Set explicitly when the sending mailbox differs from the login; otherwise it falls back to `SMTP_USER`. |
| `ENABLE_EMAIL_NOTIFICATIONS` | `false` | `true` to actually send mail. Leave `false` until SMTP is verified end to end. |
| `INVITATION_VIA_EMAIL` | `false` | `true` makes new users confirm their address before logging in. Requires working mail — turning this on with broken SMTP locks new users out. |

### File storage (attachments, exports)

⚠️ **The store must speak the S3 API.** `STORAGE_TYPE=minio` uses the MinIO
Java SDK, and `StorageServiceFactory` offers only two backends: `minio` (S3)
and `gcp` (Google Cloud Storage). **Azure Blob Storage will not work** — it has
no S3-compatible endpoint, so a `*.blob.core.windows.net` URL fails here no
matter how it is configured. On Azure this means hosting MinIO yourself, for
example a container backed by a managed disk or an Azure Files share.

⚠️ **The store must be reachable from end-user browsers, not just from the web
app.** `FileMapper` turns every file reference into a pre-signed URL on its way
out of the API, so browsers fetch every attachment, image and thumbnail
*directly* from the store — the API never proxies file bytes. A store locked to
the web app's subnet leaves every image broken. It does not have to be
internet-facing: a private endpoint with private DNS is fine as long as users
are on a network that can resolve and reach it.

Pre-signed signatures are **host-bound**: the hostname the server signs with is
the hostname the browser must use. Split-horizon DNS on the *same* name is
fine; a different external hostname invalidates the signature.

If **any** `MINIO_*` value is blank the storage client silently no-ops: the app
boots normally and uploads fail only when a user tries one.

| Variable | Example | What to put in it |
|---|---|---|
| `PUBLIC_MINIO_ENDPOINT` | `https://files.enerkem.com` | **The one that matters.** Despite the name, `MinioService.init()` builds the client on this for *everything* — uploads, downloads and signing — so it must be reachable from the web app **and** from browsers, and it is the host that ends up in pre-signed URLs. |
| `MINIO_ENDPOINT` | `https://files.enerkem.com` | Only used as an HTTP proxy target, and only when `PUBLIC_MINIO_ENDPOINT` resolves to localhost — a local-development escape hatch. It is otherwise ignored, but must still be non-empty or storage silently no-ops. In a real deployment set it to the same value as `PUBLIC_MINIO_ENDPOINT`. |
| `MINIO_BUCKET` | `atlas-bucket` | Created automatically on first boot if missing. |
| `MINIO_ACCESS_KEY` | `atlas-cmms` | Access key. |

### Entra SSO

| Variable | Example | What to put in it |
|---|---|---|
| `OAUTH2_CLIENT_ID` | *(GUID)* | Application (client) ID of the Entra app registration. |
| `OAUTH2_TENANT_ID` | *(GUID)* | **Set this for a single-tenant registration.** It defaults to `common`, which single-tenant registrations reject with `AADSTS50194`. Use the Enerkem directory (tenant) ID. |

The app registration needs redirect URI
`${PUBLIC_API_URL}/oauth2/callback/microsoft` and delegated Microsoft Graph
permissions `openid`, `email`, `profile`.

### General

| Variable | Suggested | What to put in it |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `prod` | Defaults to `dev` in `application.yml`; set `prod` for this deployment. |
| `ENABLE_CORS` | `false` | Safe to disable — the SPA and API share one origin. |
| `ALLOWED_ORGANIZATION_ADMINS` | | Comma-separated emails allowed to administer the organisation. Blank is fine. |

---

## 2. Group `atlas-cmms-secrets`

| Variable | What to put in it |
|---|---|
| `JWT_SECRET_KEY` | Signing key for the app's own session tokens. `openssl rand -base64 48`. Never reuse across environments; rotating it invalidates every active session. |
| `DB_PWD` | Password for `DB_USER`. |
| `SMTP_PWD` | Password or app-password for `SMTP_USER`. May be blank while `ENABLE_EMAIL_NOTIFICATIONS` is `false`. |
| `MINIO_SECRET_KEY` | Secret key for the object store account. |
| `OAUTH2_CLIENT_SECRET` | Client secret from the Entra app registration. **These expire** — record the expiry date, because SSO stops working silently when it lapses. |

---

## 3. Not managed by the pipeline

Set these directly on the web app if you need them; the pipeline does not
write them, so they survive deploys untouched.

| Variable | Default | Notes |
|---|---|---|
| `ENABLE_MAIL_HEALTH_CHECK` | `true` | Only affects `/actuator/health`. The app's own `/health-check` does not consult it. |
| `RATE_LIMIT_ENABLED` | `true` | Leave on. Tune with `RATE_LIMIT_AUTHENTICATED_SHORT` (100/min) and `RATE_LIMIT_AUTHENTICATED_LONG` (1000/hour). |
| `RECAPTCHA_SECRET_KEY` | empty | Only if the public request portal faces the internet. |
| `LOGO_PATHS`, `CUSTOM_COLORS`, `BRAND_CONFIG` | empty | White-labelling. JSON strings. |
| `SENDGRID_*` | empty | Only when `MAIL_TYPE=SENDGRID`. |
| `GCP_PROJECT_ID`, `GCP_BUCKET_NAME`, `GCP_JSON` | empty | Only when `STORAGE_TYPE=gcp`. |

**Licensing:** this is an AGPLv3 build with the commercial-licence gate
removed. No `LICENSE_KEY` is required and all features are available.
`LICENSE_KEY`, `LICENSE_FILE_PATH` and `LICENSE_FINGERPRINT_REQUIRED` are
ignored — leave them unset.

---

## 4. Releasing

The pipeline runs **only** on a `release/*` tag — no branch or PR builds.

### Tag format

Our release tags must carry the upstream release number they are built on:

```
release/<upstream release>-enerkem.<n>
```

The first half is the upstream Atlas CMMS release this build is merged up to;
`<n>` counts our own releases on that base and resets to 1 after each upstream
merge.

```bash
git tag release/1.6.0-enerkem.1
git push origin release/1.6.0-enerkem.1
```

The whole version (`1.6.0-enerkem.1`) becomes the build number and the
immutable image tag, alongside the moving `:prod` tag.

The first pipeline step validates this and fails the run otherwise:

| Tag | Result |
|---|---|
| `release/1.6.0-enerkem.1` | accepted while `UPSTREAM_VERSION` is `1.6.0` |
| `release/1.6.0-enerkem.12` | accepted |
| `release/1.7.0-enerkem.1` | **rejected** — upstream v1.7.0 is not merged yet |
| `release/1.6.0` | **rejected** — no `-enerkem.<n>` counter |
| `release/v1.6.0-enerkem.1` | **rejected** — no `v` prefix |

The upstream half is checked against **`UPSTREAM_VERSION`** in the repository
root, which records the upstream release the branch is merged up to and is
bumped as part of each upstream release-tag merge. It is a file rather than a
`git describe` because upstream's `v*` tags are deliberately not mirrored into
this repo — a tag newer than our merge base would drag its entire unreleased
history in with it.

If the pipeline rejects a tag because `UPSTREAM_VERSION` disagrees, the fix is
to merge the upstream release, not to edit the file.

### Stage 1 — Release

1. **Build** — one `docker build` from the repository root. `api/Dockerfile`
   zips the whole repo for AGPLv3 §13, then builds the entire Maven reactor
   inside `maven:3.9.3-eclipse-temurin-17`: Node is fetched by
   `frontend-maven-plugin`, `npm ci` and the CRA production build run, the SPA
   is copied into `classpath:/static`, and the fat jar is packaged. Runtime is
   `amazoncorretto:17-alpine`. **Java 17 throughout** — newer JDKs break Lombok
   in this codebase, so the version is pinned in the Dockerfile, not a variable.
2. **Verify** — starts Postgres and the image, waits for `/health-check`, then
   asserts the container really serves the frontend: the SPA shell at `/`,
   `asset-manifest.json`, the main JS bundle it names, a deep link
   (`/app/work-orders`) forwarding to the shell, and a non-empty
   `/source-code/download`. A jar that boots with an empty `classpath:/static`
   passes a health check and fails every one of these. The smoke test uses
   throwaway credentials against a scratch database — none of the variables
   above are involved.
3. **Publish** — pushes `cmms:prod` and `cmms:<version>` to
   `enerkem.azurecr.io`, only after the smoke test passes.

### Stage 2 — Deploy

Runs only if the Release stage succeeded. `AzureWebAppContainer@1` points
`cmms-prod` at `enerkem.azurecr.io/cmms:prod` and writes the application
settings from the variable groups. A post-deploy check then polls
`PUBLIC_API_URL` for up to 10 minutes and fails the run unless the live site
returns the SPA shell — the deploy task itself returns as soon as the platform
accepts the image, and a container that fails to start leaves the previous one
serving, which looks like success.

`WEBSITES_PORT=8080` is set automatically. It is not application config: Web
App for Containers needs it to know which port the container listens on, and
without it the platform probes the wrong port and the site returns 504.

### Rollback

`cmms:prod` moves with each release. To roll back, repoint the web app at a
specific version tag:

```bash
az webapp config container set --name cmms-prod --resource-group <rg> \
  --docker-custom-image-name enerkem.azurecr.io/cmms:1.6.0-enerkem.1
```

### Timing

Roughly **15–25 minutes** for the Release stage on a hosted agent, dominated by
`npm ci` and the CRA build. Job timeout is 120 minutes. The Deploy stage adds a
few minutes plus however long the container takes to become healthy.
