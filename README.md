# Dark / grey Software Factory

The goal of these repos is to raise the level of autonomy and automation in software development and to take laborious work off the human: agents interview, specify, design, code, test, review and maintain, while the human sets the vision and makes the decisions that matter. It is a grey factory, not yet a fully dark one: humans still review architecture and approve key changes, and the factory is meant to need fewer of those reviews over time.

**dsf-base** is the common foundation. It holds everything that does not depend on a skill pack, and every dsf-* workflow repo is built on top of it and shares its git history.

## Pick a workflow repo, not this one

Applications are started from a workflow repo. This one has no skill pack of its own.

| Repo | Skill pack | Best for |
| --- | --- | --- |
| [dsf-superpowers](https://github.com/belaboros/dsf-superpowers) | [obra/superpowers](https://github.com/obra/superpowers): brainstorm, plan, test-driven subagent execution | disciplined TDD with strong process |
| [dsf-matt-pocock](https://github.com/belaboros/dsf-matt-pocock) | [mattpocock/skills](https://github.com/mattpocock/skills): grilling interviews, PRD, issues, TDD | sharp requirements and small vertical slices |
| [dsf-addy-osmani](https://github.com/belaboros/dsf-addy-osmani) | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills): spec, plan, build, test, review, ship | broad lifecycle coverage with quality gates |
| [dsf-speckit](https://github.com/belaboros/dsf-speckit) | [GitHub Spec Kit](https://github.com/github/spec-kit): constitution, specify, plan, tasks, implement | the most formal spec-first flow |
| [dsf-hybrid](https://github.com/belaboros/dsf-hybrid) | Matt Pocock for requirements, Superpowers for execution | the recommended starting point |

```bash
git clone https://github.com/belaboros/dsf-hybrid && cd dsf-hybrid
./cloneForApplication.sh my-app --create-github --tasks github --stack typescript
```

## What dsf-base provides

| Area | Files |
| --- | --- |
| Agent rules | `CLAUDE.md` → `.dsf/CLAUDE.dsf.md` |
| Modes (design, build, factory) | `.dsf/modes.json`, enforced by `.claude/hooks/protect-paths.mjs` |
| Claude Code hooks | `.claude/hooks/`, configured in `.dsf/settings/base.json` |
| Git hooks | `.dsf/githooks/` (pre-commit, commit-msg) |
| Skills | `.claude/skills/dsf-*`: UAT interview, architect, architecture health and maintenance, factory improvement, rebuild, contribute |
| Review agents | `.claude/agents/dsf-code-reviewer.md`, `dsf-arch-reviewer.md` |
| Architecture rules and metrics | `scripts/dsf/arch/` (module rules, diagrams, cohesion and coupling report) |
| Lint and check config | `config/dsf/` (ESLint, dependency-cruiser), `.dsf/templates/stacks/typescript/` |
| CI and scheduled agents | `.github/workflows/dsf-*.yml` |
| Sync up and down the chain | `scripts/dsf/dsf-sync.sh`, `base.paths`, `dsf.paths`, `cloneForApplication.sh` |
| Documentation | [`docs/dsf/`](docs/dsf/README.md) |

## Working on dsf-base

Change it here when the improvement is useful for every workflow. Then each workflow repo picks it up with `make sync-pull` (or the weekly sync PR), and each application from its workflow repo the same way. Improvements made in a workflow repo or an app come back here with `make contribute TOPIC=<name>`; see [docs/dsf/usage.md](docs/dsf/usage.md).

Before a PR: `make check`. To test the whole chain locally: `scripts/dsf/selftest.sh`.

## Documentation

Start with [docs/dsf/README.md](docs/dsf/README.md). Setup: [docs/dsf/setup.md](docs/dsf/setup.md).
