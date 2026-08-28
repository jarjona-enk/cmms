# REQUIREMENTS.md — pipeline and deployment configuration

Every setting the Azure DevOps pipeline (`azure-pipelines.yml`) and the running
container need, what to put in each, and which ones the app refuses to start
without.

The pipeline reads two variable groups from **Pipelines → Library**. Create both
and link them to the pipeline before the first run.

| group | contents | secret |
|---|---|---|
| `atlas-cmms-build` | registry coordinates and the values baked into the SPA | no |
| `atlas-cmms-secrets` | credentials and keys | yes — back it with Azure Key Vault |

Mark every variable in `atlas-cmms-secrets` as secret in the Library UI, or link
the group to a Key Vault so the values never live in Azure DevOps at all.

---

## 1. Group `atlas-cmms-build`

### Registry — consumed by the pipeline itself

| Variable | Example | What to put in it |
|---|---|---|
| `ACR_SERVICE_CONNECTION` | `enerkem-acr` | **Name** of the Docker Registry service connection (Project settings → Service connections), not a URL. The pipeline logs in through it, so no registry password is ever stored as a variable. |
| `ACR_LOGIN_SERVER` | `enerkemacr.azurecr.io` | Fully-qualified ACR login server. Images are pushed as `$(ACR_LOGIN_SERVER)/atlas-cmms:<version>` and `:latest`, where `<version>` is the part of the `release/…` tag after the slash. |

### Baked into the SPA at build time

⚠️ **These three are compiled into the JavaScript bundle and cannot be changed
at container runtime.** Create React App substitutes them during the build, so
the published image is specific to the environment named by `PUBLIC_API_URL`.
Changing any of them requires a new build and a new release tag — you cannot
promote one image from staging to production if their URLs differ.

| Variable | Example | What to put in it |
|---|---|---|
| `PUBLIC_API_URL` | `https://cmms.enerkem.com` | Public base URL of the deployment, no trailing slash. The SPA calls the API here and Entra redirects back to `${PUBLIC_API_URL}/oauth2/callback/microsoft`, which must match the redirect URI on the app registration exactly. Because the jar serves the SPA and the API on one port, this is the same host as the UI. |
| `ENABLE_SSO` | `true` | `true` to show the "Continue with SSO" button and enable the OAuth2 login flow. Also passed to the container at runtime, where it gates the backend half. |
| `OAUTH2_PROVIDER` | `microsoft` | `microsoft` for Entra, `google` for Google. Anything else disables the provider. |

---

## 2. Group `atlas-cmms-secrets`

| Variable | What to put in it |
|---|---|
| `JWT_SECRET_KEY` | Signing key for the application's own session tokens. Generate a long random string (`openssl rand -base64 48`) and never reuse it across environments. Rotating it invalidates every active session. |
| `DB_PWD` | Password for `DB_USER`. |
| `SMTP_PWD` | Password or app-password for `SMTP_USER`. Leave empty only if `ENABLE_EMAIL_NOTIFICATIONS` is `false`. |
| `MINIO_SECRET_KEY` | Secret key for the object store account. |
| `OAUTH2_CLIENT_SECRET` | Client secret from the Entra app registration. Secrets expire — note the expiry, because SSO stops working silently on that date. |

---

## 3. Runtime configuration for the container

Set on the container at deploy time (App Service application settings, AKS
secret, `.env` next to the jar for the systemd unit — whichever host you use).
Keeping these out of the image is what makes the backend half of the config
promotable without a rebuild.

### Required — the application will not start without these

`application.yml` gives them no default, so Spring fails placeholder resolution
at startup and the container exits.

| Variable | Example | What to put in it |
|---|---|---|
| `DB_URL` | `atlas-db.postgres.database.azure.com:5432/atlas` | **Host:port/database only.** The `jdbc:postgresql://` prefix is added by `application.yml`; including it yourself produces a malformed URL. |
| `DB_USER` | `atlas` | Database user. Needs DDL rights: Liquibase runs the changelog on every boot and JPA validates the schema afterwards. |
| `DB_PWD` | *(from secrets)* | See above. |
| `JWT_SECRET_KEY` | *(from secrets)* | See above. |
| `PUBLIC_API_URL` | `https://cmms.enerkem.com` | Same value as the build-time variable. The backend builds absolute links with it. |
| `PUBLIC_FRONT_URL` | `https://cmms.enerkem.com` | Where the OAuth2 success handler sends the browser after login (`${PUBLIC_FRONT_URL}/oauth2/success?token=…`). Same host as the API in this single-origin deployment. |
| `MAIL_RECIPIENTS` | `cmms-admins@enerkem.com` | Comma-separated addresses for system notifications. Must be set even when email is disabled — it has no default. |
| `STORAGE_TYPE` | `minio` | `minio` or `gcp`. Selects the file-attachment backend. |

### Database

| Variable | Default | What to put in it |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `dev` | Set to `prod` for a real deployment. |

### Mail server

| Variable | Default | What to put in it |
|---|---|---|
| `MAIL_TYPE` | `SMTP` | `SMTP` or `SENDGRID`. |
| `SMTP_HOST` | `smtp.gmail.com` | SMTP server hostname. For Microsoft 365, `smtp.office365.com`. |
| `SMTP_PORT` | `587` | 587 for STARTTLS, which is what the app is configured for. |
| `SMTP_USER` | *(empty)* | Account used to authenticate. |
| `SMTP_PWD` | *(from secrets)* | See above. |
| `SMTP_FROM` | falls back to `SMTP_USER` | Envelope From address. Set it explicitly when the sending mailbox differs from the login. |
| `ENABLE_EMAIL_NOTIFICATIONS` | `false` | `true` to actually send mail. Leave `false` until SMTP is verified. |
| `INVITATION_VIA_EMAIL` | `false` | `true` makes new users confirm their address before logging in. Requires working mail. |
| `ENABLE_MAIL_HEALTH_CHECK` | `true` | Set `false` if no SMTP server is reachable, so mail does not drag the health endpoint down. |
| `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL`, `SENDGRID_CONTACT_LIST_ID` | empty | Only when `MAIL_TYPE=SENDGRID`. |

### File storage (attachments, exports)

Attachments and exports need this. If any `MINIO_*` value is blank the storage
client silently no-ops — the app boots fine and uploads fail at use time.

| Variable | Example | What to put in it |
|---|---|---|
| `MINIO_ENDPOINT` | `http://minio:9000` | URL the **server** uses to reach the object store, i.e. the internal address. |
| `PUBLIC_MINIO_ENDPOINT` | `https://files.enerkem.com` | URL the **browser** uses for pre-signed download links. Often differs from the above; getting them backwards produces links that only work from inside the network. |
| `MINIO_BUCKET` | `atlas-bucket` | Created automatically on first boot if missing. |
| `MINIO_ACCESS_KEY` | `atlas-cmms` | Access key. |
| `MINIO_SECRET_KEY` | *(from secrets)* | See above. |
| `GCP_PROJECT_ID`, `GCP_BUCKET_NAME`, `GCP_JSON` | — | Only when `STORAGE_TYPE=gcp`. `GCP_JSON` is the service-account JSON inline. |

### Entra SSO

| Variable | Example | What to put in it |
|---|---|---|
| `ENABLE_SSO` | `true` | Enables the OAuth2 login flow. This build gates SSO on this flag alone — no commercial licence key is involved. |
| `OAUTH2_PROVIDER` | `microsoft` | See above. |
| `OAUTH2_CLIENT_ID` | *(GUID)* | Application (client) ID of the Entra app registration. |
| `OAUTH2_CLIENT_SECRET` | *(from secrets)* | See above. |
| `OAUTH2_TENANT_ID` | *(GUID)* | **Set this for a single-tenant app registration.** It defaults to `common`, which single-tenant registrations reject with `AADSTS50194`. Use the Enerkem directory (tenant) ID. |

The Entra app registration needs redirect URI
`${PUBLIC_API_URL}/oauth2/callback/microsoft` and delegated Microsoft Graph
permissions `openid`, `email`, `profile`.

### Licensing

This is an AGPLv3 build with the commercial-licence gate removed, so **no
`LICENSE_KEY` is required** and all features are available. `LICENSE_KEY`,
`LICENSE_FILE_PATH` and `LICENSE_FINGERPRINT_REQUIRED` are ignored — leave them
unset.

### Optional

| Variable | Default | What to put in it |
|---|---|---|
| `ENABLE_CORS` | `true` | Can be `false` in this single-origin deployment; the SPA and API share a host. |
| `RATE_LIMIT_ENABLED` | `true` | Leave on. Tune with `RATE_LIMIT_AUTHENTICATED_SHORT` (default 100/min) and `RATE_LIMIT_AUTHENTICATED_LONG` (default 1000/hour). |
| `RECAPTCHA_SECRET_KEY` | empty | Only if the public request portal is exposed to the internet. |
| `ALLOWED_ORGANIZATION_ADMINS` | empty | Comma-separated emails allowed to administer the organisation. |
| `LOGO_PATHS`, `CUSTOM_COLORS`, `BRAND_CONFIG` | empty | White-labelling. JSON strings. |
| `CLOUD_VERSION` | `false` | Keep `false`. Multi-tenant SaaS behaviour. |

---

## 4. Releasing

The pipeline runs **only** on a `release/*` tag — no branch or PR builds.

```bash
git tag release/1.0.0
git push origin release/1.0.0
```

The version is the part after the slash (`1.0.0`) and becomes both the build
number and the image tag. A tag that is not `release/<something>` fails the
first step deliberately.

What the run does:

1. **Build** — one `docker build` from the repository root. `api/Dockerfile`
   zips the whole repo for AGPLv3 §13, then builds the entire Maven reactor
   inside `maven:3.9.3-eclipse-temurin-17`: Node is downloaded by
   `frontend-maven-plugin`, `npm ci` and the CRA production build run, the SPA
   is copied into `classpath:/static`, and the fat jar is packaged. Runtime is
   `amazoncorretto:17-alpine`. **Java 17 throughout** — newer JDKs break Lombok
   in this codebase, so the version is pinned in the Dockerfile, not a variable.
2. **Verify** — starts Postgres and the image, waits for `/health-check`, then
   asserts the container really serves the frontend: the SPA shell at `/`,
   `asset-manifest.json`, the main JS bundle it points at, a deep link
   (`/app/work-orders`) forwarding to the shell, and a non-empty
   `/source-code/download`. A jar that boots but serves no SPA is the exact
   failure this packaging is designed to prevent, and a health check alone
   cannot see it.
3. **Publish** — pushes to ACR only after the smoke test passes.

The smoke test uses throwaway credentials against a scratch Postgres, so none
of the variables above are used for it. They configure the real deployment.

Expect **roughly 15–25 minutes** on a hosted agent, dominated by `npm ci` and
the CRA build. The job timeout is 120 minutes.

### Not yet wired

There is no deploy stage — the pipeline publishes an image and stops. Adding
one needs a decision on the target (App Service, AKS, or the `cmms.service`
systemd unit on a VM), which is what the runtime variables in §3 would feed.
