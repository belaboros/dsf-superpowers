---
name: dsf-factory-improve
description: Improve the Dark / gray Software Factory itself - upgrade skill packs and tools, turn repeated human corrections into deterministic rules and hooks, and tune the review and architect agents. Use in factory mode, when the weekly dsf-factory-improve workflow runs, or when the human asks to make the factory more autonomous.
---

# Factory improvement

Goal: the same mistake should never need a human or an LLM a third time, and the factory should need fewer approvals over time without getting worse. Work in factory mode (`make factory`). Every change goes in a PR the human approves.

## 1. Collect evidence (last 7 days unless told otherwise)

- `factory/logs/sessions.jsonl`: hook blocks, stop-check rounds and escalations per session.
- Pull requests: `gh pr list --state merged --search "merged:>=<date>"`, then for each PR the review comments (`gh api repos/{owner}/{repo}/pulls/<n>/comments`), commits the human pushed on top of agent work, and reverted commits (`git log --grep '^Revert'`).
- Architecture decisions: proposals and how the human decided; ADRs superseded soon after acceptance.
- CI failures on main and their causes.

## 2. Turn repeats into deterministic checks

Group the evidence by root cause. For each cause seen twice or more, pick the cheapest guard that would have caught it, in this order: a type or compiler setting; an ESLint rule (in `config/dsf/eslint.base.mjs` if generic, `eslint.config.js` if app-specific); a dependency-cruiser rule or module rule; a test helper or fixture; a hook; a skill instruction. Each new rule ships with a small test case or fixture showing it flags the past mistake and passes on correct code.

## 3. Tune agent judgment

- Code review agent: precision = findings the human accepted / all findings; misses = bugs or corrections found after merge that it did not flag. Propose edits to `.claude/agents/dsf-code-reviewer.md` for the worst cases.
- Architect agent: decisions the human overrode, and why. Propose edits to `dsf-architect`.
- Gates: if a human gate (for example `ARCH_REVIEW=before`) passed 10 times in a row with no change requested, propose relaxing it, with the numbers.

## 4. Upgrades (in the dsf-* parent repos, monthly)

- Tools: `npm outdated` on the stack template; bump versions in `.dsf/templates/stacks/*/package.json`.
- Skill packs: check the versions of the plugins in `.dsf/settings/workflow.json` and the upstream changelogs.
- Accept an upgrade only after the benchmark (`docs/dsf/factory-evolution.md#benchmark`) is not worse on first-pass check rate, stop-check rounds and architecture health.

## 5. Report

Open one PR per kind of change (rules, hooks, skills, upgrades) with a short table: evidence, change, expected effect. If the change is generic (useful for every app), commit it separately from app files so it can be sent to the parent with `make contribute TOPIC=<topic>`.
