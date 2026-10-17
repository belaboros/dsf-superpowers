# Factory rules (from dsf-base)

You work inside a Dark / gray Software Factory: agents specify, design, build, test, review and maintain software; the human sets the vision and makes the decisions that matter. Raise autonomy without lowering quality.

## Where things live

- `specs/` vision, PRD, feature specs. `uat/features/` acceptance scenarios (Gherkin). Both are the contract; the code is replaceable.
- `docs/architecture/` overview with ASRs, `modules.json` (module map), `adr/` decision records, `generated/` rules and diagrams (from `make arch-rules`), `proposals/`.
- `src/` code, organised by the modules in `modules.json`. `uat/steps/` acceptance test steps.
- `arch/health/` cohesion and coupling reports. `factory/logs/` session logs (written by hooks).
- Factory files: `.claude/`, `.dsf/`, `scripts/dsf/`, `config/dsf/`, `docs/dsf/`, `Makefile`. Application-specific skills go in `.claude/skills/app-*`.
- Tasks: the backend in `.dsf.app` (`TASKS_BACKEND`), explained in `CLAUDE.app.md`.

## Modes (separation of duties)

`DSF_MODE` is `design`, `build` or `factory` (`make design|build|factory`). Hooks refuse edits outside the current mode: design never writes production code, build never changes specs, acceptance scenarios or architecture, factory changes only the factory. If the task needs a protected file changed, stop and say so; do not work around the hook.

## Workflows

Pick one per request (the prompt hook suggests it) and follow `docs/dsf/workflows.md`; `.dsf/CLAUDE.workflow.md` names the skill-pack commands for each step.
- **bugfix:** reproduce with a failing test, fix, `make check`, review, PR.
- **feature:** vision, interview, PRD, UAT interview (`dsf-uat-interview`), architecture (`dsf-architect`), human review if `ARCH_REVIEW=before`, plan into tasks, build test-first, review (`dsf-code-reviewer`), PR.
- **exploration:** research, prototype on a `spike/` branch, write findings and options, the human decides; prototypes are never merged as is.
- **factory:** `dsf-factory-improve`, `dsf-contribute`.

## Loops you work in

1. Test loop: write a failing test, make it pass, refactor.
2. Edit loop: the PostToolUse hook formats and lints each edited file; fix what it reports before moving on.
3. Task loop: the Stop hook runs `make check`; you cannot finish while it fails. After 5 failed rounds you are stopped: write the blocker into the task with what you tried and mark it for the human.
4. PR loop: CI and the review agent must pass; at most 3 review rounds, then ask the human.
5. Weekly: `dsf-arch-maintenance` and `dsf-factory-improve` propose; the human decides.

## Never

- Weaken, skip, delete or loosen a test, rule, threshold or hook to get green. Fix the code, or escalate.
- Commit with `--no-verify`, force-push, or push straight to `main`. Work on a branch and open a PR.
- Mix factory files and application files in one commit (the pre-commit hook enforces this).
- Change an accepted ADR's decision; write a new ADR that supersedes it.

## Always

- Small vertical slices, each with tests, each leaving `make check` green.
- Link every PR to its task and spec section. Commit messages start with a type: `feat`, `fix`, `test`, `refactor`, `docs`, `spec`, `arch`, `uat`, `dsf`, `chore`.
- When you notice a repeated mistake, suggest the deterministic rule that would prevent it.
