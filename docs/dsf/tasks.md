# Tasks and tickets

Chosen once per application with `cloneForApplication.sh --tasks <backend>` and stored as `TASKS_BACKEND` in `.dsf.app`. `CLAUDE.app.md` tells agents how to use the chosen one.

| Backend | Where tasks live | Strengths | Weaknesses | Pick it when |
| --- | --- | --- | --- | --- |
| `markdown` | `tasks/NNNN-slug.md` in the repo | no tools, versioned with the code, works offline, agents edit files directly | no board, no notifications, dependencies only by convention | solo, laptop-first, simplest start (default) |
| `backlog` | `backlog/` in the repo, via [Backlog.md](https://github.com/MrLesk/Backlog.md) | Markdown in git plus a CLI, Kanban board, web view and MCP server for agents | one more tool to install | you want files in git and a board |
| `beads` | `.beads/` in the repo, via [Beads](https://github.com/steveyegge/beads) (`bd`) | built for coding agents: dependency graph, `bd ready` lists unblocked work, long-lived agent memory | younger tool, less human-friendly | many agents working in parallel on long plans |
| `github` | GitHub Issues on the app repo | notifications, mobile app, links to PRs, labels drive workflow, visible to collaborators | needs the network and `gh`; not versioned with the code | others follow along, or you use the GitHub mobile app |

Also considered and left out for now: Linear and Jira (strong for teams, but a paid SaaS outside the repo and another connector for agents) and GitHub Projects (a board on top of Issues; add it to the `github` backend when you want one).

Every backend uses the same vocabulary, so skills do not change with the backend:

- type: `feature`, `bug`, `arch-decision`, `dsf` (generic factory improvement), `research`
- status: `todo`, `doing`, `blocked`, `done`, plus `needs-human` when a decision is waiting on you
- each task links its spec section and UAT scenarios

Changing the backend later is possible but manual: export the open tasks, edit `TASKS_BACKEND` in `.dsf.app`, and replace the tasks section of `CLAUDE.app.md`.
