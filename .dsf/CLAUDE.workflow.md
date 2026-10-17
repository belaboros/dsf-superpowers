# Workflow layer: Superpowers

Skill pack: [obra/superpowers](https://github.com/obra/superpowers) (plugin `superpowers@superpowers-marketplace`). Its skills trigger on their own; the table says which one each factory step uses and where its output goes in this factory.

| Factory step (docs/dsf/workflows.md) | Mode | Superpowers skill | Output goes to |
| --- | --- | --- | --- |
| PRD interview | design | `brainstorming` (one question at a time, then a design) | `specs/prd.md` |
| UAT interview | design | `dsf-uat-interview` (factory skill) | `uat/features/` |
| Architecture | design | `dsf-architect` (factory skill); use `brainstorming` to compare options | `docs/architecture/` |
| Plan into tasks | design | `writing-plans` | `plans/<date>-<feature>.md`, plus one task per plan step in the task backend |
| Build | build | `subagent-driven-development` (or `executing-plans`), each step with `test-driven-development`, in a worktree from `using-git-worktrees` | `src/`, tests, `uat/steps/` |
| Bugfix | build | `systematic-debugging`, then `test-driven-development` | failing test first, then the fix |
| Review | build | `requesting-code-review`, which must use the `dsf-code-reviewer` agent; `receiving-code-review` for answering it | PR comments |
| Finish | build | `verification-before-completion` (run `make check`), then `finishing-a-development-branch`, choosing "open a pull request" | PR |
| Exploration | design | `brainstorming`, prototype on a `spike/` branch | `docs/architecture/proposals/` |
| Factory | factory | `dsf-factory-improve`; `writing-skills` for new `app-*` or `dsf-*` skills | `.claude/skills/` |

Where Superpowers and this factory differ, the factory wins:

- Superpowers saves designs in `docs/superpowers/specs/` and plans in `docs/superpowers/plans/`. Here, designs go to `specs/` (feature designs in `specs/features/<feature>.md`) and plans to `plans/`.
- `finishing-a-development-branch` may offer to merge locally. Never merge into `main`; always open a PR.
- Worktrees go in `.worktrees/` (ignored by git). Run `make check` inside the worktree.
