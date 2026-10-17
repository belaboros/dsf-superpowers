---
name: dsf-rebuild
description: Rebuild the application from its specification with a different architecture or implementation while keeping its functionality, using the PRD and UAT scenarios as the contract. Use only when the human asks for a rebuild or a re-architecture experiment.
---

# Rebuild from the specification

The spec (`specs/`) and the acceptance tests (`uat/features/`) are the contract; the code is replaceable.

1. Confirm the goal with the human: which architecture or stack to try, and what must be better (measurable: health metrics, performance, size).
2. Create a branch `rebuild/<name>`. Keep `specs/`, `uat/features/`, `docs/architecture/adr/` (history) and the factory files. Move the old `src/`, `docs/architecture/modules.json` and generated files out of the build (delete on the branch; they stay on main).
3. Run `dsf-architect` for the new architecture: new modules, a new ADR that supersedes the old structure, `make arch-rules`.
4. Implement with the normal build workflow, task by task, until `make check` and `make uat` pass with all `@critical` scenarios green.
5. Compare old and new: UAT pass rate, `make arch-health` metrics, size and performance numbers. Write the comparison into the PR and let the human choose.
