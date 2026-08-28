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
