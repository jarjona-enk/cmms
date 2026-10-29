---
name: openwolf
description: OpenWolf operating protocol for this project. Load when starting multi-file work, resuming a session, wrapping up a session, or when unsure how to use .wolf/ state files (anatomy, cerebrum, memory, buglog, STATUS).
---

# OpenWolf (token-lean)

The protocol is `.wolf/OPENWOLF.md` (already imported by CLAUDE.md); follow it. In short:

- Resume: read `.wolf/STATUS.md`. Wrap up: rewrite it (≤1k tokens) and add one line to `.wolf/memory.md`.
- Before coding: read `.wolf/cerebrum.md` (≤3k tokens). Older context: grep `.wolf/*-archive.*`, never read whole.
- Bugs: `openwolf bug search "<error>"` first; log only non-obvious bugs.
- Learnings: bar is HIGH, one line each, keep cerebrum under 3k tokens.
- Hooks maintain `anatomy.md` and `memory.md`; `openwolf find <name>` locates code.
