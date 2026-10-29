# OpenWolf (token-lean protocol)

Goal: keep the context small. Every line read stays in context for every later call.

- **Resume:** read `.wolf/STATUS.md` first (short handoff). When a quest ends, rewrite it (≤1k tokens: production state, next step, open decisions) and add one line to `.wolf/memory.md`.
- **Before coding:** read `.wolf/cerebrum.md` (≤3k tokens, active rules). For older context grep `.wolf/cerebrum-archive.md`; never read an archive whole.
- **Finding code:** `openwolf find <name>` or Grep/Glob; read files with offset/limit when large. Never read `.wolf/anatomy.md`, `memory.md` or `buglog.json` whole.
- **Bugs:** before fixing, `openwolf bug search "<error>"`. Log only bugs whose cause was not obvious (root cause + fix); not routine edits or retries.
- **Learnings:** the bar is HIGH. Add to cerebrum only a rule that prevents a real, likely repeat of a mistake, or a lasting user preference; one line each. Keep the file under 3k tokens: merge or move old entries to the archive.
- **Hooks** maintain `anatomy.md` and `memory.md`; do not edit them by hand.
- **Command output:** prefer narrow commands (grep -n, head, --stat, -q). Large build/test output is summarized; the full log is in `.wolf/cache/bash/`.
- On-demand skills: `/designqc`, `/reframe`, `/security-audit`, `/handoff`.
