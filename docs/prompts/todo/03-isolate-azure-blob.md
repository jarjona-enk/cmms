# Phase 3 — isolate the Azure Blob implementation

**Model: Claude Sonnet 5.5, effort high.** Tests, docs and an isolation audit against an exact file list; high effort for the security review of SAS generation and managed-identity auth.

Phase 3 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

## Task

Read CLAUDE.md, DEVELOPMENT-STATUS.md and ENERKEM-PLAN.md (Directive,
Governing principle, Decisions, Facts). `enerkem` is at upstream v1.9.0.
Local only; no pushes. Goal: make the Azure Blob Storage backend a cleanly
separable, upstream-quality feature **on `enerkem` itself**, with no change
in behaviour for production. Work on `enerkem` directly (small commits).

1. **Audit.** `git log -S AzureBlobService --oneline enerkem` and
   `git diff v1.9.0..enerkem -- api/src/main/java/com/grash/service/AzureBlobService.java
   api/src/main/java/com/grash/model/enums/StorageType.java
   api/src/main/java/com/grash/factory/StorageServiceFactory.java
   api/src/main/resources/application.yml api/pom.xml`. List every Azure line,
   and every non-Azure Enerkem line in the shared files (SSO, mail, packaging)
   so the two are never confused.
2. **Upstream quality, in place:**
   - dependencies via `com.azure:azure-sdk-bom` in `<dependencyManagement>`
     (latest stable from Maven Central; check with `curl
     "https://search.maven.org/solrsearch/select?q=g:com.azure+AND+a:azure-sdk-bom&rows=1&wt=json"`),
     versionless `azure-storage-blob` and `azure-identity`; remove the two
     `azure.*.version` properties;
   - `AzureBlobService` implements the full current `StorageService` (`upload`
     ×2, `download` ×2, `generateSignedUrl` ×2 via `CacheService`, `uploadAt`,
     `exists`) with `GCPService` as the reference for semantics and error
     codes; keep both auth modes (account key; `DefaultAzureCredential` /
     managed identity with user-delegation SAS) — that is the feature's value;
   - wording: no "Enerkem", no internal host names or ticket references in
     comments or messages; env names stay `AZURE_STORAGE_ACCOUNT`,
     `AZURE_STORAGE_ACCOUNT_KEY`, `AZURE_STORAGE_CONTAINER`,
     `AZURE_STORAGE_ENDPOINT` (production depends on them);
   - `StorageServiceFactoryTest`: `getStorageService_azure_returnsAzureService`
     in the existing style (`@Mock AzureBlobService`, `ReflectionTestUtils`);
   - **extend `AzureBlobServiceTest` (Mockito, no Docker; created in Phase 1)**: mock `BlobServiceClient`
     / `BlobContainerClient` / `BlobClient`; cover `upload` (unique path,
     content type), `download` (missing blob → `CustomException` 404),
     `uploadAt` (empty → 400; overwrite), `exists` true/false,
     `generateSignedUrl` in shared-key mode and in user-delegation mode and
     that the `File` overload goes through `CacheService`, and the
     not-configured guard;
   - **Azurite integration test** (`AzureBlobServiceIT`, Testcontainers
     `GenericContainer("mcr.microsoft.com/azure-storage/azurite")` exposing
     10000, shared-key mode with Azurite's well-known dev account): real
     upload → exists → download bytes equal → signed URL fetchable → `uploadAt`
     overwrite → `exists` false for a missing path. Skip cleanly when Docker is
     unavailable (`@Testcontainers(disabledWithoutDocker = true)`);
   - docs in upstream's pattern: `AZURE-setup.md` at the repo root mirroring
     `GCP-setup.md` (create storage account + container; either an account key
     or a managed identity with *Storage Blob Data Contributor* + *Storage Blob
     Delegator*; note that browsers download via SAS URL on the blob host, so
     the account must be reachable from users' browsers — a private-only
     account needs DNS that resolves to its private endpoint); README env-table
     rows (`STORAGE_TYPE` → `gcp | minio | azure`, the four `AZURE_*` variables)
     and a link to `AZURE-setup.md` next to the GCP one; `.env.example` entries;
     `docker-compose.yml` passthrough of the four variables.
3. **Prove it.** `mvn -DskipFrontend=true test` (with `DOCKER_HOST=tcp://localhost:2375`)
   is green including the new tests; `git diff v1.9.0..enerkem -- <the Azure
   files and the Azure hunks of the shared files>` contains the whole feature
   and nothing else; a local run with `STORAGE_TYPE=minio` is unchanged.
4. Record in DEVELOPMENT-STATUS.md the exact file list and hunk list that
   constitutes the contribution (this list is what Phase 4 copies). Commit on
   `enerkem`. Tell the owner whether any behaviour changed; if it did, propose
   `release/1.9.0-enerkem.2` and print the push/tag commands (do not run them).

## QA and acceptance

- `mvn -DskipFrontend=true test` green with `DOCKER_HOST=tcp://localhost:2375`, including the extended
  `AzureBlobServiceTest`, `StorageServiceFactoryTest` azure case and `AzureBlobServiceIT` (Azurite).
- `git diff v1.9.0..enerkem` over the Azure files/hunks contains the whole feature and nothing else; no "Enerkem",
  internal hosts or tickets in the Azure code/comments; env names unchanged.
- `AZURE-setup.md`, README rows, `.env.example`, `docker-compose.yml` passthrough present; a `STORAGE_TYPE=minio` run is
  unchanged.
- **Security review** (our code only): SAS tokens are read-only, short-lived and scoped to one blob; no account key,
  SAS or connection string is logged; managed-identity mode needs only *Storage Blob Data Contributor* + *Storage Blob
  Delegator*; no path traversal out of the container; not-configured guard fails closed. Findings in DEVELOPMENT-STATUS.
- DEVELOPMENT-STATUS lists the exact contribution file + hunk list (Phase 4 copies it); behaviour change reported.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation: to be filled (tokens in / out / cache read / cache write, cost in USD).
