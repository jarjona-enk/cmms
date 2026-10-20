# Memory

> Chronological action log. Hooks and AI append to this file automatically.
> Old sessions are consolidated by the daemon weekly.

## Session: 2026-08-28 — fork hygiene, CI/CD, Azure Blob, OpenTofu

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 10:05 | Audited fork topology; found `origin` pointed at upstream `Grashjs/cmms` and all Enerkem work was uncommitted (0 ahead, 507 behind) | — | Boundary missing; advised split | 4k |
| 10:12 | Safety bundle of all refs before touching anything | `scratchpad/cmms-backup-20260828.bundle` | 89 MB written | 1k |
| 10:15 | Verified `.idea/` has zero upstream churn; kept it tracked instead of ignoring | `.idea/*` | Reversed earlier advice | 1k |
| 10:20 | Committed pre-existing work as 8 themed commits on `51341f8e` | 34 tracked + 16 untracked | Tree clean | 12k |
| 10:35 | Wrote fork + merge policy: release tags only, one at a time, never rebase | `CLAUDE.md` | Policy recorded | 4k |
| 10:40 | Re-fetched upstream tags — `v1.7.0` (+16) and `v1.8.0` (+228) exist; corrected earlier claim | — | Merge backlog known | 1k |
| 10:45 | Secret-scanned the diff before first push | — | Clean; only variable names | 1k |
| 11:00 | SSH push to Azure DevOps failed `publickey`; switched `origin` to HTTPS + PAT | `.git/config` | Push unblocked | 2k |
| 11:20 | First Azure DevOps pipeline: tag trigger, container build, SPA smoke test, ACR push | `azure-pipelines.yml` | YAML valid | 8k |
| 11:30 | Found Dockerfile could not receive the SPA build URL — every image baked `localhost:8080` | `api/Dockerfile` | Added 3 build args | 2k |
| 11:45 | Documented every pipeline and runtime variable | `REQUIREMENTS.md` | 29 vars, all cross-checked | 6k |
| 12:10 | Added `UPSTREAM_VERSION` gate so release tags must carry the upstream release number | `UPSTREAM_VERSION`, `azure-pipelines.yml`, `CLAUDE.md` | 8 tag cases tested | 5k |
| 12:40 | Traced storage: `FileMapper` hands signed URLs to the browser; API never proxies bytes | `MinioService.java`, `FileMapper.java` | Store must be browser-reachable | 3k |
| 12:50 | Corrected two documentation errors: Azure Blob is not S3-compatible; `MINIO_ENDPOINT` is not the server-side URL | `REQUIREMENTS.md` | Both were mine | 3k |
| 13:20 | Implemented Azure Blob backend — managed identity + user delegation SAS, shared-key fallback, cached delegation key | `AzureBlobService.java` (new), `StorageType.java`, `StorageServiceFactory.java`, `application.yml`, `api/pom.xml` | `mvnw compile` BUILD SUCCESS | 14k |
| 14:10 | Read live Azure via `az`/MCP instead of asking for an export | — | Found conventions, VNets, DB topology | 6k |
| 14:23 | Wrote OpenTofu: bootstrap + module + test/prod envs | `infra/**` | 8 files | 16k |
| 14:35 | `tofu validate` caught a dependency cycle on the system-assigned identity | `infra/modules/cmms/main.tf` | Switched to user-assigned | 4k |
| 14:45 | Reworked pipeline for two environments, tofu stages, prod approval gate | `azure-pipelines.yml`, `.azure/steps-deploy.yml` | YAML valid | 9k |
| 15:00 | Rewrote REQUIREMENTS around Tofu-owned config; 6 non-secret vars, Key Vault for secrets | `REQUIREMENTS.md` | All refs cross-checked | 7k |
| 15:20 | Identified blocking network problem: intended DB is canadacentral, apps are canadaeast | `DEVELOPMENT-STATUS.md` §11 | Raised to user | 3k |
| 15:35 | User chose `10.225.1.107` (budget's server); confirmed via `itbudget` app settings and its subnet | `infra/envs/*/main.tf` | Blocker resolved | 4k |
| 15:40 | Renamed `db_fqdn` → `db_host`; `tofu fmt` had realigned the line so the first patch missed | `infra/modules/cmms/*` | validate + fmt clean | 2k |
| 16:03 | Saved cross-session memory: build state, fork/release process, Azure infrastructure | `~/.claude/projects/C--data-src-cmms/memory/*` | 3 files + index | 5k |
| 15:50 | Filled OpenWolf files per protocol | `.wolf/cerebrum.md`, `.wolf/memory.md`, `.wolf/buglog.json`, `.wolf/anatomy.md` | This entry | 8k |

### Session summary

Turned an unversioned working copy into a proper downstream fork with a documented
merge policy, then built the whole delivery path: a two-environment Azure DevOps
pipeline triggered by `test/*` and `release/*` tags, an Azure Blob storage backend,
and OpenTofu owning both environments' infrastructure and configuration.

**Commits:** 13 on `main`, `51341f8e` → `35692d3a`, all pushed to `origin`.

**Verified, not assumed:** `mvnw compile` BUILD SUCCESS for the Azure backend;
`tofu validate` + `tofu fmt` clean on all three configs; both pipeline YAML files
parse; all pipeline variable references cross-checked against REQUIREMENTS.md; tag
validation exercised against 8 cases; smoke-test assumptions checked against the
actual code (`/health-check`, `id="root"`, `SpaForwardController` routes,
`MinioService` no-op path).

**Not verified:** nothing has been applied to Azure. No `tofu apply`, no pipeline
run, no deployed container. The infrastructure is validated HCL, not running
infrastructure.

**Outstanding for the user:** two `/28` subnets in `RG-CanEast-Tier1` delegated to
`Microsoft.Web/serverFarms` (`10.225.5.48/28`, `10.225.5.64/28` are free);
`oauth2_client_id` is a `REPLACE-WITH-…` placeholder in both env files; the
`atlas-cmms-build` variable group and the `cmms-prod` environment need creating;
the service principal needs **User Access Administrator** (Contributor cannot grant
the role assignments); Key Vaults must be seeded between first apply and first
deploy. Upstream `v1.7.0` (+16 commits) is pending review and must not be merged
unprompted.
| 16:05 | Session end: 4 writes across 4 files (atlas-cmms-internal-build-state.md, atlas-cmms-fork-and-release-process.md, atlas-cmms-azure-infrastructure.md, MEMORY.md) | 1 reads | ~2870 tok |

## Session: 2026-09-10 17:11

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 17:22 | Created .azure/steps-deploy.yml | — | ~1147 |
| 17:29 | Created api/container/sshd_config | — | ~88 |
| 17:29 | Created api/container/startup.sh | — | ~283 |
| 17:30 | Edited api/Dockerfile | expanded (+43 lines) | ~646 |
| 17:31 | Created .azure/steps-deploy.yml | — | ~2023 |
| 17:31 | Edited azure-pipelines.yml | 3→3 lines | ~36 |
| 17:31 | Edited azure-pipelines.yml | 7→11 lines | ~154 |
| 17:31 | Edited azure-pipelines.yml | 8→8 lines | ~91 |
| 17:31 | Edited azure-pipelines.yml | 3→3 lines | ~41 |
| 17:32 | Edited azure-pipelines.yml | 13→18 lines | ~312 |
| 17:32 | Edited azure-pipelines.yml | 2→5 lines | ~94 |
| 17:36 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/req_update.py | — | ~4279 |
| 17:37 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/req_append.py | — | ~1594 |
| 17:38 | Edited .azure/steps-deploy.yml | expanded (+9 lines) | ~179 |
| 17:38 | Edited .azure/steps-deploy.yml | 7→7 lines | ~150 |
| 17:40 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs_update.py | — | ~1732 |
| 17:40 | Edited CLAUDE.md | expanded (+6 lines) | ~134 |
| 17:41 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/devstatus.py | — | ~3624 |
| 17:44 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/wolf_update.py | — | ~3388 |
| 17:52 | Edited azure-pipelines.yml | expanded (+7 lines) | ~218 |
| 17:55 | Edited .dockerignore | expanded (+19 lines) | ~205 |
| 17:55 | Edited api/Dockerfile | 8→12 lines | ~80 |
| 17:56 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-935e-57654313f459/scratchpad/wolf2.py | — | ~4 |
| 17:57 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/wolf2.py | — | ~4398 |

## Session summary — 2026-09-10

Four owner decisions, all implemented: (1) OpenTofu out of the pipeline entirely,
which also drops the User Access Administrator requirement from the service
principal; (2) prod DB is `db-caneast-pmdms`, referenced via two read-only data
sources, host taken from the private endpoint (`10.225.1.104`) because the FQDN
resolves to the server's public address with no privatelink DNS zone linked;
(3) `:latest` pushed on every release — which is the tag the hand-made
`cmms` site-containers app actually pulls, so a `test/…` tag currently
redeploys production; (4) sshd on 2222 + log teed to `/home/cmms/atlas.log`,
ported from `../budget`, runtime base image moved to `eclipse-temurin:17-jre-noble`.

Found and fixed three latent defects while verifying: a cross-stage
`task.setvariable` reference in my own preflight; a hyphenated `JWT_SECRET_KEY`
in the CI smoke test that would have failed every run on `Illegal base64
character 2d`; and `dev.env` plus 754 MB of OpenTofu provider binaries reaching
the publicly served AGPLv3 source bundle (278 MB -> 93 MB after the
`.dockerignore` fix).

Verified in the real image: builds clean, boots to `/health-check` in 7s, sshd
on `0.0.0.0:2222`, app on `:::8080`, full Spring log in `/home/cmms/atlas.log`,
SPA and source bundle both served. `tofu validate` + `fmt` clean on both envs;
both pipeline YAML files parse.

Still blocking a real deploy: `cmms` has no app settings, no VNet integration,
and `keyVaultReferenceIdentity` points at a non-existent system-assigned
identity. REQUIREMENTS.md §7.
| 17:59 | Session end: 24 writes across 13 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 0 reads | ~25003 tok |
| 18:05 | Edited prod.env | expanded (+26 lines) | ~396 |
| 18:05 | Session end: 25 writes across 14 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 0 reads | ~25427 tok |
| 18:18 | Edited infra/envs/prod/main.tf | 3→3 lines | ~41 |
| 18:18 | Edited infra/envs/prod/main.tf | expanded (+10 lines) | ~208 |
| 18:19 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/dbname.py | — | ~1126 |
| 18:19 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/record.py | — | ~1250 |
| 18:20 | Session end: 29 writes across 17 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 0 reads | ~28070 tok |
| 09:53 | Edited infra/envs/prod/main.tf | 2→2 lines | ~11 |
| 09:54 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/dbuser.py | — | ~1325 |
| 09:55 | Session end: 31 writes across 18 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 0 reads | ~29407 tok |
| 10:32 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/status.py | — | ~2832 |
| 10:32 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-internal-build-state.md | — | ~865 |
| 10:33 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-azure-infrastructure.md | — | ~1986 |
| 10:34 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/MEMORY.md | — | ~300 |

## Session summary — 2026-09-11

Follow-ups to the 2026-09-10 session, then a full records pass.

Changes: prod `db_name` and `db_user` are both **`atlas`** (was `atlasprod`/`atlasprod`),
matching `prod.env`; `variable "public_url"` in `infra/envs/prod/main.tf` now
defaults to `https://cmms.enerkem.com` instead of requiring `TF_VAR_public_url`,
which nothing supplies now that OpenTofu is out of the pipeline. Azure Blob
variables were added to `prod.env` after the MinIO block. Production no longer
follows the user-matches-database `atlasprod` convention; test still does.

Records pass: rewrote DEVELOPMENT-STATUS.md START HERE around the real blockers
(all Azure-side config, not code), retracted the role-name warnings once the
owner settled it, removed a duplicate `## infra/envs/prod/` section from
anatomy.md and enriched the auto-generated one-liners for `.dockerignore`,
`azure-pipelines.yml` and `steps-deploy.yml`, noted in cerebrum that `cmms`
breaks the `<env>-<app>` naming convention, and refreshed four persistent
memories — most importantly correcting the `10.225.1.107` database claim, which
was a test server, and dropping the stale "pipeline needs User Access
Administrator" requirement.

Verified: `tofu validate` + `fmt` clean on both envs after each edit;
`nslookup cmms.enerkem.com` still NXDOMAIN; ACR repository `cmms` still does not
exist. Nothing committed — working tree carries all of it.

Single biggest open item: `cmms` cannot boot a container (no app settings, no
VNet integration, `keyVaultReferenceIdentity` pointing at an identity that does
not exist), and `cmms.enerkem.com` must be real before the first image build
because the URL is compiled into the SPA bundle.
| 10:35 | Edited infra/README.md | expanded (+12 lines) | ~303 |
| 10:35 | Edited DEVELOPMENT-STATUS.md | expanded (+6 lines) | ~186 |
| 10:35 | Edited DEVELOPMENT-STATUS.md | 6→11 lines | ~192 |
| 10:36 | Session end: 38 writes across 24 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 1 reads | ~36343 tok |
| 13:32 | Created .azure/env/prod.env | — | ~533 |
| 13:32 | Created .azure/env/test.env | — | ~303 |
| 13:32 | Edited azure-pipelines.yml | 13→14 lines | ~198 |
| 13:33 | Edited azure-pipelines.yml | expanded (+23 lines) | ~626 |
| 13:33 | Edited azure-pipelines.yml | 3→3 lines | ~58 |
| 13:33 | Created .azure/steps-deploy.yml | — | ~2408 |
| 13:35 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/envfile.py | — | ~2022 |
| 13:36 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/record128.py | — | ~1528 |

## Session note — 2026-09-11 (pipeline config)

Replaced the `atlas-cmms-build` variable group with committed
`.azure/env/prod.env` + `.azure/env/test.env`, five non-secret keys each.
Declined to ship the root `prod.env` to CI as a secure file: the pipeline needs
no secrets now that it writes no app settings and applies no infrastructure, so
handing it any would only widen the blast radius. Both the Build job and the
deploy template source the file independently, because `task.setvariable` is
job-scoped. Validated the parse logic locally including a negative test. See
DEVELOPMENT-STATUS.md §12.8.
| 13:37 | Session end: 46 writes across 27 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 1 reads | ~44079 tok |
| 13:49 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/secrets.py | — | ~2124 |
| 13:51 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/record129.py | — | ~1943 |

## Session note — 2026-09-11 (secret storage)

Settled secret storage: per-env Key Vault + unversioned app-setting references,
resolved by the app's user-assigned identity. Rewrote REQUIREMENTS.md section 2
with the runnable sequence and a management table. Found that the old section 2
instructed an impossible command (empty Key Vault secret value) - logged as
bug-028. Confirmed no CMMS vault exists yet, and that only DB_PWD and
JWT_SECRET_KEY are boot-critical (no defaults in application.yml); SMTP_PWD has
a default and should simply be omitted. See DEVELOPMENT-STATUS.md section 12.9.
| 13:51 | Session end: 48 writes across 29 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 1 reads | ~48146 tok |
| 13:56 | Created .azure/env/prod.env | — | ~835 |
| 13:59 | Created azure-pipelines.yml | — | ~5938 |
| 13:59 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/park.py | — | ~1694 |
| 14:00 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/prodonly.py | — | ~2152 |
| 14:01 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/sec35.py | — | ~1231 |
| 14:02 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/deploydesc.py | — | ~1390 |
| 14:03 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/record1210.py | — | ~4718 |

## Session note — 2026-09-11 (park tofu, production-only pipeline)

Parked OpenTofu behind a banner in infra/README.md and rewrote CLAUDE.md 2b
around the hand-built environment. Rebuilt azure-pipelines.yml as a single
production-only job in the itsheets/budget shape: release/* trigger, build,
smoke-test, push :<version> + :latest, AzureWebAppContainer@1 onto `cmms` with
non-secret appSettings, poll, log. Deleted .azure/steps-deploy.yml and
.azure/env/test.env. Expanded .azure/env/prod.env to the full non-secret set.

Two divergences from itsheets/budget, both deliberate: plain `docker build`
(Docker@2 buildAndPush ignores `arguments`, so --build-arg would be dropped and
localhost:8080 baked into the SPA), and the smoke test kept.

Two problems surfaced from Azure: `stgcaneastcmms` has publicNetworkAccess
Disabled with defaultAction Deny, which breaks the browser-side SAS download
path the app depends on (uploads would still work); and
AzureWebAppContainer@1 will convert `cmms` off the site-containers model on
first run. Both flagged, neither silently decided. See DEVELOPMENT-STATUS.md
section 12.10.
| 14:04 | Session end: 55 writes across 34 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 2 reads | ~71154 tok |
| 14:50 | Created .gitattributes | — | ~312 |
| 14:51 | Created .gitattributes | — | ~357 |
| 14:52 | Session end: 57 writes across 35 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 2 reads | ~71870 tok |
| 15:35 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/checkvars.py | — | ~853 |
| 15:35 | Session end: 58 writes across 36 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 2 reads | ~72723 tok |
| 18:16 | Session end: 58 writes across 36 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 2 reads | ~72723 tok |
| 18:26 | Session end: 58 writes across 36 files (steps-deploy.yml, sshd_config, startup.sh, Dockerfile, azure-pipelines.yml) | 2 reads | ~72723 tok |

## Session: 2026-09-11 19:39

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 20:50 | Created scripts/setup-keyvault.ps1 | — | ~4571 |
| 20:52 | Edited scripts/setup-keyvault.ps1 | modified with() | ~218 |
| 20:54 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/smtp_docs.py | — | ~1314 |
| 20:55 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/status1211.py | — | ~2456 |
| 20:56 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/wolf1211.py | — | ~2664 |

## Session note — 2026-09-11 (DevOps verification, mail, Key Vault script)

Verified the Azure DevOps pipeline with the CLI before its first run and found
it would not have worked: service connection ids were from another project
(they are project-scoped), there were two pipelines on the same repo and YAML
racing each other, pipeline 41 was not authorised for the Azure connection, and
the deploy SPN had no deploy permission. Fixed all four - deleted the duplicate,
corrected the ids, authorised the pipeline, granted Website Contributor.
Confirmed AcrPush/AcrPull and the storage roles (incl. Blob Delegator) were
already right.

Graph is blocked by Conditional Access here, so role assignments have to be read
via `az rest` on ARM and principals addressed by object id.

Mail: smtp.enerkem.com:25, no auth. Discovered SMTP_AUTH/SMTP_STARTTLS are inert
- application.yml hardcodes them - and that leaving SMTP_USER empty is what
actually skips authentication.

Wrote scripts/setup-keyvault.ps1. Shipped it with a parameter-binding bug the
owner hit immediately (`-o` ambiguous, from naming a param $Args on an advanced
function); fixed and then actually ran it with -WhatIf, which is what I should
have done first. Also corrected AZURE_STORAGE_CONTAINER from a guessed
atlas-files to the real `cmms`. See DEVELOPMENT-STATUS.md section 12.11.
| 20:57 | Session end: 5 writes across 4 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py) | 0 reads | ~11565 tok |
| 21:00 | Edited api/src/main/resources/application.yml | 4→7 lines | ~96 |
| 21:01 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/smtp_wire.py | — | ~1228 |

## Session note - 2026-09-11 (SMTP made configurable)

Owner: "change application.yaml, add the variables or it won't work" then
"Set INVITATION to true. Follow my settings."

Parameterised properties.mail.smtp.auth and starttls.enable in application.yml
as ${SMTP_AUTH:true} / ${SMTP_STARTTLS:true} - defaults kept true so upstream
behaviour is unchanged - and wired both through .azure/env/prod.env and the
pipeline. Set INVITATION_VIA_EMAIL=true and ENABLE_CORS=true, and aligned
DB_URL, per the owner reaffirming after I flagged the invitation risk.

Found a stray second properties.mail.smtp block misindented under spring.jpa
(upstream noise, does nothing) - left alone. Also corrected my own earlier
doubt: SMTP_FROM IS read, via @Value in EmailService2.

Only three keys now differ between prod.env and .azure/env/prod.env:
MAIL_RECIPIENTS (cannot be blank or the app will not boot) and MAIL_TYPE
(uppercase to match the enum constant exactly).
| 21:03 | Session end: 7 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~12889 tok |
| 21:05 | Session end: 7 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~12889 tok |
| 21:14 | Session end: 7 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~12889 tok |

## Session note - 2026-09-13 (first release attempt)

Pipeline "failure" was a manual run against refs/heads/main, correctly rejected
by the tag guard. The real defect: the tag release/1.6.0-enerkem.1 was pushed
and queued NO run - `branches: exclude '*'` plus a separate `tags:` block fires
nothing in Azure DevOps. Rewritten as
`branches: {include: ['refs/tags/release/*']}`. Tag must be deleted and
re-pushed on the fix. Also split the guard's error message into three cases.

Readiness checked live: vault + secrets + Secrets User role all done, all
non-secret app settings present, but the three Key Vault reference settings are
missing and keyVaultReferenceIdentity is still SystemAssigned - steps 4 and 5 of
setup-keyvault.ps1. Container cannot boot until those are fixed. See
DEVELOPMENT-STATUS.md 12.12.
| 12:55 | Session end: 7 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~12889 tok |
| 09:00 | Edited scripts/setup-keyvault.ps1 | added 3 condition(s) | ~906 |
| 09:00 | Edited scripts/setup-keyvault.ps1 | modified Invoke() | ~536 |

## Session note - 2026-09-14 (setup-keyvault.ps1 review)

Owner hit "JWT_SECRET_KEY was unexpected at this time" on the app-settings
step. Cause: on Windows az is az.cmd, so cmd.exe re-parses arguments and the
';' '(' ')' in a Key Vault reference break it. Fixed by writing the settings to
a temp JSON file and using --settings @file; payload shape verified against
`az webapp config appsettings list`.

The error output also revealed a worse bug of mine: Invoke-Az threw the raw
command line, so a failure during `az keyvault secret set` would have printed
the real secret. Added a redaction list plus Hide-Secrets over every error
string.

Error reporting rebuilt: a trap prints the failing section, the az exit code,
az's output and a likely-cause hint for recognisable messages, instead of a
PowerShell code frame. Verified with -WhatIf; keyVaultReferenceIdentity now
reads as already fixed, so only the app settings remain.
| 09:04 | Session end: 9 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~14434 tok |

## Session note - 2026-09-14 (database grants)

Checked the atlas database via the idea MCP (the intellij MCP server does not
connect). Database owner was already atlas, but the public SCHEMA was owned by
azure_pg_admin and atlas had USAGE without CREATE - the PostgreSQL 15+ default.
Liquibase would have failed the first container start with "permission denied
for schema public", which would have read as a bad release rather than a
missing grant.

Fixed with ALTER SCHEMA public OWNER TO atlas + GRANT ALL ON SCHEMA public TO
atlas. Schema had 0 objects so nothing to migrate. Verified by running
CREATE/INSERT/INDEX/ALTER/DROP under SET LOCAL ROLE atlas and confirming no
leftovers - not just by reading the ACL. See DEVELOPMENT-STATUS.md 12.13.
| 16:38 | Session end: 9 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~14434 tok |
| 16:58 | Session end: 9 writes across 6 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~14434 tok |
| 17:04 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/save1214.py | — | ~4014 |

## Session summary - 2026-09-14 (first real deploy)

The pipeline ran and deployed cmms:1.6.0-enerkem.2. Two blockers cleared, one
open.

CLEARED: the "permission denied for schema public" crash loop was the 12.13
grant working - the pasted log predated it, and App Service had STOPPED the site
after repeated cold-start failures so nothing retried. Verified the grant was
still in place, replayed the exact Liquibase DDL as role atlas, then started the
site: 802 changesets, 138 tables, 85 sequences, lock released cleanly. Database
side is done.

CLEARED: AzureBlobService failed with "Managed Identity authentication is not
available" because the app has only a user-assigned identity and AZURE_CLIENT_ID
was unset. Set it (dbb349c1 = ua-id-9ca4) and committed it to
.azure/env/prod.env + the pipeline. Owner asked whether that was OAUTH2_CLIENT_ID
- it is not: different principal, holds no Azure RBAC role, verified against the
storage account's assignments.

OPEN: no privatelink.blob.core.windows.net DNS zone, so the storage FQDN
resolves to the blocked public address even though routing is fine (same VNet).
Same trap as the database FQDN. Decide: link a blob private DNS zone (also fixes
browser downloads) or enable public network access on the account.

Also logged: startup.sh masks java's exit code via `| tee`, which is why every
failure reads "exit code 0"; and the app's real output lives in
LogFiles/StartupLogs/<date>_<host>_failure.log, not docker.log.

App is currently STOPPED. See DEVELOPMENT-STATUS.md 12.14.
| 17:04 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-internal-build-state.md | — | ~842 |
| 17:06 | Session end: 11 writes across 8 files (setup-keyvault.ps1, smtp_docs.py, status1211.py, wolf1211.py, application.yml) | 0 reads | ~19350 tok |

## Session: 2026-09-15 20:36

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-09-15 21:15

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session note - 2026-09-15 (Entra registration swapped)

OAUTH2_CLIENT_ID changed to f08d1fe7-... with a new secret; both were already in
the repo-root prod.env and on the live app. Caught that the COMMITTED
.azure/env/prod.env still had the old id - the deploy task pushes that key every
release, so the next tag would have reverted sign-in. Fixed there plus the docs
quoting it.

Pushed the new secret with setup-keyvault.ps1 (new KV version 2026-09-15
01:21). Verified by hash that the vault matches prod.env, and App Service now
reports all three Key Vault references Resolved - which also confirms the
keyVaultReferenceIdentity fix and vault RBAC work. App picks it up on next
restart; still stopped and still blocked on blob DNS (12.14).

## Session note - 2026-09-15 (the app is UP)

Reviewed the application log: Atlas CMMS is running. Started 01:22 in 86s,
/health-check and / both 200 with the SPA shell. Managed identity token for
storage: SUCCESS - the AZURE_CLIENT_ID fix works. Liquibase reports the DB up to
date, 802 previously run.

I was WRONG about the blob DNS being the next blocker: containerClient.exists()
succeeded, so the app reaches stgcaneastcmms. The remaining question is only
whether end-user BROWSERS can resolve that hostname for SAS download URLs -
untested.

The log's errors are mostly noise: internet exploit scanners (PHP/WordPress/SQLi
probes rejected by Tomcat's parser - but they prove the site is public with
'Allow all' as its only access restriction), and a runtime-env.js 404 per page
load from frontend/public/index.html line 35 requesting a file this build never
generates. Everything else is cosmetic. See DEVELOPMENT-STATUS.md 12.16.
| 22:30 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/striptests.py | — | ~1940 |
| 22:31 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/notests_docs.py | — | ~2363 |

## Session note - 2026-09-15 (tests removed from the pipeline)

Owner: "remove all the tests you do during the build. Just limit to build a
working container and deploy it. If it doesn't work we will fix it."

Deleted the five smoke-test steps (postgres, start container, verify SPA, logs,
teardown). 13 steps -> 8, 457 lines -> 367. Build now tags :<version> and
:latest directly; the candidateTag indirection is gone.

Kept, and said why: tag/UPSTREAM_VERSION validation (release policy), env-key
validation (PUBLIC_URL is compiled into the SPA), the container log dump, and
the post-deploy site check downgraded to informational (continueOnError,
3-minute cap, warning not failure) so a dead release is still visible without
blocking.

Noted the cost rather than arguing it again: the smoke test is what caught the
JWT_SECRET_KEY base64 bug. See DEVELOPMENT-STATUS.md 12.17.
| 22:32 | Session end: 2 writes across 2 files (striptests.py, notests_docs.py) | 0 reads | ~4303 tok |

## Session: 2026-09-15 22:35

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 22:58 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/run-local.sh | — | ~564 |
| 23:07 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/resolve-v180.py | — | ~955 |
| 23:13 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/api-smoke.sh | — | ~1101 |
| 23:42 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/api-smoke2.sh | — | ~1385 |
| 23:55 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-v180.py | — | ~6390 |

## Session note - 2026-09-15 (upstream v1.7.0 + v1.8.0 merged)

Found an in-progress merge of upstream/main on main; aborted with consent.
Merged v1.7.0 (1 conflict, en.ts) then v1.8.0 (3 conflicts: .gitignore,
api/pom.xml, OAuth2AuthenticationSuccessHandler) on merge/upstream-* branches.
UPSTREAM_VERSION 1.6.0 -> 1.7.0 -> 1.8.0 inside the merges. SSO changes intact.
Owner allow-listed UNACCENT on db-caneast-pmdms (needed by a v1.8.0 changeset).
Local tests on :8085: fresh install 806 changesets, upgrade 802+4, API suite
8/8 twice, browser login + grids, SSO redirect pinned to tenant. Traps: stale
gitignored SPA copy in api/src/main/resources/static; Git Bash curl UTF-8
mangling; MAIL_RECIPIENTS/MinIO for local runs. See DEVELOPMENT-STATUS 12.18.
| 23:56 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-fork-and-release-process.md | — | ~1087 |
| 23:56 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-internal-build-state.md | — | ~865 |
| 00:05 | Session end: 7 writes across 7 files (run-local.sh, resolve-v180.py, api-smoke.sh, api-smoke2.sh, docs-v180.py) | 0 reads | ~12703 tok |

## Session: 2026-09-15 08:27

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-09-15 08:42

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-09-15 08:42

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 09:37 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-close.py | — | ~869 |
| 09:37 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-internal-build-state.md | — | ~839 |

## Session end - 2026-09-15 09:40

Owner verified SSO on the local 1.8.0 build (port 8080). App + MinIO stopped.
Root cause of all silent process deaths: cybermap session's `taskkill //IM
java.exe` (correlated by timestamp). Docs, cerebrum, buglog, memory updated;
committed on main. Owner tags release/1.8.0-enerkem.1 and pushes.
| 09:38 | Session end: 2 writes across 2 files (docs-close.py, atlas-cmms-internal-build-state.md) | 0 reads | ~1768 tok |
| 10:27 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-branch-model.py | — | ~2915 |

## 2026-09-15 09:55 - branch model change

Owner: our code moves to branch `enerkem`; `main` mirrors upstream/main.
Created enerkem from main (3bdcc06c), reset main to upstream/main (50db0808),
tracking set (enerkem->origin/enerkem, main->upstream/main). Docs: CLAUDE.md
sections 1-2, REQUIREMENTS 5, DEVELOPMENT-STATUS 12.19, cerebrum. Owner pushes.
| 10:29 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-fork-and-release-process.md | — | ~1127 |
| 10:29 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 10:44 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 10:44 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |

## 2026-09-15 11:15 - release/1.8.0-enerkem.1 deployed

Pipeline run 5985 succeeded; app Running, health 200, SPA baked with the public URL. Findings: container logging Off on the app (stdout never captured); deploy task put the app in DOCKER| mode. DEVELOPMENT-STATUS 12.20.
| 11:10 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 11:49 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 12:52 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 14:51 | Session end: 4 writes across 4 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md) | 0 reads | ~5890 tok |
| 16:40 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-dns.py | — | ~3682 |
| 16:41 | Created ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/atlas-cmms-azure-infrastructure.md | — | ~2095 |

## 2026-09-15 13:00 - post-deploy diagnosis (DNS x2), context saved

cmms.enerkem.com: corporate A record -> 10.225.2.20 (wrong App Service PE, 503); public path works with the new DigiCert cert; owner fixing DNS. Blob download 403: VPN NRPT lacks blob.core.windows.net so browsers hit the public IP of a private-only storage account; three options given, decision pending. Roles: own_user.role_id -> role. DEVELOPMENT-STATUS 12.21. Nothing running locally; enerkem has unpushed docs commits.
| 16:41 | Session end: 6 writes across 6 files (docs-close.py, atlas-cmms-internal-build-state.md, docs-branch-model.py, atlas-cmms-fork-and-release-process.md, docs-dns.py) | 0 reads | ~11817 tok |

## Session: 2026-09-16 09:54

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-09-16 09:55

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 10:01 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-mail.py | — | ~1428 |

## 2026-09-16 10:15 - mail review

Not a credentials problem: EXO Direct Send rejects MAIL_RECIPIENTS=cmms-admins@enerkem.com (does not exist). User mails work. 'Invalid credentials' = failed logins. DEVELOPMENT-STATUS 12.22.
| 10:01 | Session end: 1 writes across 1 files (docs-mail.py) | 0 reads | ~1428 tok |
| 14:26 | Edited api/src/main/java/com/grash/service/EmailService2.java | added 1 import(s) | ~35 |
| 14:26 | Edited api/src/main/java/com/grash/service/EmailService2.java | 4→5 lines | ~29 |
| 14:26 | Edited api/src/main/java/com/grash/service/EmailService2.java | modified catch() | ~152 |
| 14:26 | Edited api/src/main/java/com/grash/service/EmailService2.java | added 1 condition(s) | ~241 |
| 14:27 | Edited api/src/main/java/com/grash/service/EmailService2.java | 4→5 lines | ~62 |
| 14:28 | Edited api/src/main/java/com/grash/service/UserService.java | added 1 import(s) | ~20 |
| 14:28 | Edited api/src/main/java/com/grash/service/UserService.java | 4→5 lines | ~15 |
| 14:28 | Edited api/src/main/java/com/grash/service/UserService.java | modified catch() | ~236 |
| 14:28 | Edited api/src/main/java/com/grash/service/UserService.java | 2→4 lines | ~99 |
| 14:30 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/mail-test.sh | — | ~931 |
| 14:33 | Edited api/src/main/java/com/grash/service/EmailService2.java | 5→9 lines | ~130 |
| 14:33 | Edited api/src/main/java/com/grash/service/EmailService2.java | — | ~0 |
| 14:36 | Edited api/src/main/java/com/grash/service/EmailService2.java | 9→13 lines | ~202 |
| 14:36 | Edited api/src/main/java/com/grash/service/EmailService2.java | added 1 import(s) | ~34 |
| 14:40 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-mail2.py | — | ~2865 |

## 2026-09-16 14:45 - invitations fixed

Root cause of 'lost invites': the invitee's REGISTRATION failed (admin copy to non-existent cmms-admins@enerkem.com threw synchronously; class-level @Transactional made it rollback-only). Fixed in EmailService2 (logging, NOT_SUPPORTED) and UserService (catch Exception, invite log). Verified with MailHog and a refusing relay. DL still to be created. DEVELOPMENT-STATUS 12.23.
| 14:41 | Session end: 16 writes across 5 files (docs-mail.py, EmailService2.java, UserService.java, mail-test.sh, docs-mail2.py) | 2 reads | ~6635 tok |
| 15:01 | Session end: 16 writes across 5 files (docs-mail.py, EmailService2.java, UserService.java, mail-test.sh, docs-mail2.py) | 2 reads | ~6635 tok |
| 16:28 | Session end: 16 writes across 5 files (docs-mail.py, EmailService2.java, UserService.java, mail-test.sh, docs-mail2.py) | 2 reads | ~6635 tok |
| 16:54 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-close2.py | — | ~1653 |

## Session end - 2026-09-16 17:00

release/1.8.0-enerkem.2 deployed (run 5998), health 200. cmms-admins mailbox now exists; MMolotkov registered (user 9); tchaves invitations deleted via psql (MCP DML times out). Open: DNS x2 (12.21), container logging off (12.20). DEVELOPMENT-STATUS 12.24.
| 16:55 | Session end: 17 writes across 6 files (docs-mail.py, EmailService2.java, UserService.java, mail-test.sh, docs-mail2.py) | 2 reads | ~8288 tok |

## Session: 2026-09-16 17:00

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-09-16 17:00

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-10-19 12:17

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-10-19 12:18

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|

## Session: 2026-10-19 12:19

| Time | Action | File(s) | Outcome | ~Tokens |
|------|--------|---------|---------|--------|
| 12:32 | Created ENERKEM-PLAN.md | — | ~3892 |
| 12:32 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-plan.py | — | ~1271 |

## 2026-10-19 - plan written

Owner wants: merge v1.9.0 + test, isolate Azure Blob, then upstream PR. Wrote ENERKEM-PLAN.md (Prompts 0-5) with the facts (v1.9.0 = fc27abfd, Boot 3.5.16, axios removed, StorageService uploadAt/exists, 8 changesets, no extensions). No code changed. DEVELOPMENT-STATUS 12.25.
| 12:33 | Session end: 2 writes across 2 files (ENERKEM-PLAN.md, docs-plan.py) | 0 reads | ~5441 tok |
| 12:46 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-tests.py | — | ~1766 |

## 2026-10-19 13:00 - tests

First ever `mvn test`: 767 run, 0 failures, 2 Testcontainers errors (Docker Desktop 29 named-pipe incompatibility, all workarounds tried). No Azure Blob tests exist; plan amended (identical-bytes rule; Mockito unit tests + Azurite IT in Prompt 3). Azurite image pulled. DEVELOPMENT-STATUS 12.26.
| 12:47 | Session end: 3 writes across 3 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py) | 0 reads | ~7207 tok |
| 12:50 | Session end: 3 writes across 3 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py) | 0 reads | ~7207 tok |
| 12:54 | Created ../../../Users/JArjona/.ssh/config | — | ~47 |
| 12:55 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-fork.py | — | ~809 |

## 2026-10-19 13:20 - fork wired

Owner created github.com/jarjona-enk/cmms and an SSH key ~/.ssh/jarjona-enk. Added ~/.ssh/config Host github.com -> that key; remote `fork` set to SSH; `ssh -T` says Hi jarjona-enk; ls-remote and dry-run push OK. Nothing pushed.
| 12:55 | Session end: 5 writes across 5 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py, config, docs-fork.py) | 0 reads | ~8066 tok |
| 13:05 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-author.py | — | ~520 |
| 13:05 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-models.py | — | ~650 |
| 13:06 | Session end: 7 writes across 7 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py, config, docs-fork.py) | 0 reads | ~9236 tok |
| 13:43 | Created ENERKEM-PLAN.md | — | ~7752 |
| 13:43 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-directive.py | — | ~652 |

## 2026-10-19 14:10 - plan finalised

Owner decisions baked into ENERKEM-PLAN.md: LOCAL ONLY (no production, no pushes/tags by sessions), upstream package files as-is, prefer-upstream on uncovered conflicts, local test DB only, Docker over TCP 2375 (owner enabling), port 8080 required for SSO check, session pushes contrib/* to fork and owner opens issue/PR, author Juan F Arjona - Enerkem Inc. Docker update wiped containers; recreate commands in the plan. Prompt 0 is ready to run on Sonnet 5.
| 13:44 | Session end: 9 writes across 8 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py, config, docs-fork.py) | 1 reads | ~21843 tok |
| 13:54 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-ready.py | — | ~1356 |
| 14:02 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-ready.py | — | ~2696 |
| 14:02 | Edited ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-ready.py | present() → count() | ~113 |
| 14:02 | Edited ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-ready.py | modified rep() | ~55 |

## 2026-10-19 14:40 - pre-flight for agent execution

Docker TCP 2375 on; root cause of Testcontainers failures = Docker 29 rejects API<1.40 -> fixed with api.version=1.44 in ~/.docker-java.properties; full suite 863/1 failure (expected: usage-limit test vs AGPL decision). Prod copy restored locally by owner (806 changesets, 7 users); baseline dump in atlas_backups. MinIO now bitnamilegacy image; MailHog running. Plan updated for coordinated background agents.
| 14:03 | Session end: 13 writes across 9 files (ENERKEM-PLAN.md, docs-plan.py, docs-tests.py, config, docs-fork.py) | 1 reads | ~26063 tok |
| 00:27 | Created ../../../Users/JArjona/AppData/Local/Temp/claude/C--data-src-cmms/8cea39fc-76dc-4a3a-95ce-57654313f459/scratchpad/docs-bye.py | — | ~2003 |

## Session end - 2026-10-19

Pre-flight done and recorded (DEVELOPMENT-STATUS 12.28): LOCAL ONLY, prod copy in local atlas + baseline dump, Docker 29 fix (TCP + api.version=1.44), suite 863/1 expected failure, containers recreated (bitnamilegacy/minio), fork over SSH verified. Blocked on disk (9.9 GB < 10 GB). Next: owner frees disk, says go -> coordinator launches Prompt 0 (Sonnet) -> 1 (Opus) -> 2 (Sonnet) as background agents. enerkem has unpushed docs commits.
