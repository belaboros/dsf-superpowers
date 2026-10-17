# Factory evolution

The factory is a product too, improved on a schedule, with evidence, and with the human approving each change. The aim is to need the human less over time without lowering quality.

## The weekly routine

`dsf-factory-improve` runs every Monday (GitHub Actions, factory mode) and on request (`make factory`, then ask for it).

1. **Collect evidence** from the last week: `factory/logs/sessions.jsonl` (hook blocks, Stop-hook rounds, escalations), merged PRs with their review comments, commits a human pushed on top of agent work, reverts, overridden architecture decisions, CI failures on main.
2. **Turn repeats into deterministic checks.** A mistake seen twice gets the cheapest guard that would have caught it: compiler setting, then lint rule, then module rule, then test helper, then hook, and only last a skill instruction. Each new rule comes with a fixture showing it flags the old mistake.
3. **Tune agent judgment.** Review agent precision and misses; architect decisions the human overrode; human gates that passed many times unchanged (candidates to relax, with the numbers).
4. **Upgrade** skill packs and tools (monthly, in the parent repos), only when the benchmark is not worse.
5. **Report** as PRs, one per kind of change, each with a table: evidence, change, expected effect.

Generic improvements are committed apart from app changes and sent to the parent with `make contribute`, so every application benefits.

## Benchmark

Run before accepting an upgrade or a large factory change, and compare with the last run:

| Measure | Source |
| --- | --- |
| first-pass check rate: tasks whose first Stop-hook `make check` was green | `factory/logs/sessions.jsonl` |
| average Stop-hook rounds per task, and escalations | `factory/logs/sessions.jsonl` |
| review findings per PR, and their precision | PR comments |
| human corrections per PR | commits by the human on agent branches |
| architecture health deltas | `arch/health/history/` |
| UAT pass rate | `make uat` |

A simple, repeatable benchmark: keep a small reference app (a few features with UAT scenarios), rebuild one feature on a branch with the old and the new factory, and compare the table.

## Toward a darker factory

Gates move from the human to checks in this order, each only when the numbers support it: formatting and lint (already automatic), module rules and health gates, code review for small changes, architecture review for changes inside a module, and last, architecture decisions across modules. `ARCH_REVIEW=after` is the first step on the architecture side.
