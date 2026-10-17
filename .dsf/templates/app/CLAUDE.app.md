# {{APP_NAME}}: application notes

This repo was created from the Dark Software Factory parent `{{PARENT_URL}}`.
Generic factory instructions live in `.dsf/CLAUDE.dsf.md` (imported by `CLAUDE.md`); this file holds what is specific to {{APP_NAME}}.

## Architecture review

The human reviews architecture changes **{{ARCH_REVIEW}}** implementation (`ARCH_REVIEW` in `.dsf.app`; see the `dsf-architect` skill).

## Tasks and tickets

Tasks are stored in: **{{TASKS_BACKEND}}**. {{TASKS_HINT}}

## Generic vs application changes

- Files listed in `dsf.paths` belong to the factory. Improve them freely, but commit them separately from application changes (the pre-commit hook enforces this).
- Send generic improvements back with `scripts/dsf/dsf-sync.sh contribute <topic>`.
- Pull factory updates with `scripts/dsf/dsf-sync.sh pull`.
- Application-specific skills and agents go in `.claude/skills/app-*` and `.claude/agents/app-*`.
