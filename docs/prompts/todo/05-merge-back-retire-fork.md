# Phase 5 — after upstream merges it: merge back, retire the fork

**Model: Claude Opus 5.5, effort high.** An upstream release merge like Phase 1, plus proving the no-op; a conflict here means the identical-bytes rule broke and needs judgement.

Phase 5 of the living plan `ENERKEM-PLAN.md`. Run it only on Juan's okay, in a clean context, on that model.
Read `CLAUDE.md` (Rules, "When coding software", §1-§3) first. Local only: no pushes, no tags, no `az`, no
production (ENERKEM-PLAN.md -> Directive). Never delete a branch. Commit messages end with `LLM: Claude <model>`
(no `Co-Authored-By`). When done: set this phase's status in ENERKEM-PLAN.md, update DEVELOPMENT-STATUS.md, fill
the Cost section below, and list the branches not yet on `origin`. Juan moves this file to `docs/prompts/done/`
when he accepts the result.

## Task

Read CLAUDE.md and ENERKEM-PLAN.md. Upstream released a version containing
the Azure Blob backend (tag `<vX.Y.Z>` — the owner names it). Merge that
release into `enerkem` per CLAUDE.md §2 and this plan's Phase 1 rules
(local only, no pushes, no tags, owner hands over the tag). During the merge
verify that `AzureBlobService.java`, the Azure tests, `StorageType`,
`StorageServiceFactory`, the `storage.azure.*` YAML block, the Azure
dependencies and the Azure docs merge as **no-ops** (identical bytes). If any
of them conflicts, the identical-bytes rule was broken somewhere — stop and
report which side drifted before resolving. Re-run the Phase 2 matrix.
Update CLAUDE.md "Known conflict hot spots" to remove the Azure files from our
conflict surface. End with the push/tag commands for the owner.

**Retire the fork** (Juan, 2026-10-29: once upstream ships the Azure backend and it is merged back, the fork is no
longer needed): remove the `fork` remote row and the Azure-Blob upstream exception from CLAUDE.md §1, the fork lines
from `.wolf/cerebrum.md`, and mark the plan finished in ENERKEM-PLAN.md. Do not run, print for the owner:
`git remote remove fork`, and the reminder that the owner deletes the GitHub fork `jarjona-enk/cmms`. Keep the local
`contrib/azure-blob-storage` branch (never delete branches; it is on `origin`).

## QA and acceptance

- The upstream release tag (named by Juan) merged per CLAUDE.md §2 on a kept `merge/upstream-vX.Y.Z` branch;
  `UPSTREAM_VERSION` bumped inside the merge.
- The Azure files merge as **no-ops** (identical bytes); any conflict was stopped and reported, not resolved blind.
- Phase 2 matrix re-run and green.
- **Security review** of any conflict resolved in SSO, mail or storage code (our lines only).
- CLAUDE.md hot spots, §1 (fork removed), cerebrum and ENERKEM-PLAN.md updated; owner commands printed, nothing run.

## Cost

- Planning: 2026-10-29 alignment session (Opus 5.5), recorded in `docs/prompts/done/URGENT-TODO.md`.
- Implementation: to be filled (tokens in / out / cache read / cache write, cost in USD).
