---
name: dsf-contribute
description: Send generic factory improvements made in this repo back up the chain (application -> dsf-* repo -> dsf-base), and pull factory updates down. Use when a commit changed factory files, when the human asks to share an improvement, or when the weekly sync runs.
---

# Moving factory changes along the chain

The chain is `dsf-base -> dsf-<workflow> -> application`. Ownership is defined by `dsf.paths` (what an application must send to its dsf-* repo) and `base.paths` (what a dsf-* repo must send to dsf-base).

- Commit factory changes separately from application changes; the pre-commit hook rejects mixed commits. Message prefix `dsf:`.
- Check what can go up: `make sync-status` (commits marked `up`).
- Send them: `make contribute TOPIC=<short-topic>`. This cherry-picks only the parent-owned commits onto the parent's main and opens a PR there.
- In a dsf-* repo, after merging such a PR, run `make contribute TOPIC=<topic>` again: commits touching only `base.paths` go on to dsf-base.
- Pull updates: `make sync-pull` merges the parent's main; files marked `=` (README, generated settings) keep this repo's version, and `.claude/settings.json` is regenerated.
- Something app-specific inside a factory folder (a skill only this app needs) goes under an `app-` prefix (`.claude/skills/app-*`) so it never leaves the app.
