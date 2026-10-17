# Rebuild from the specification

The factory keeps the contract separate from the implementation so the app can be rebuilt with a different architecture or stack, and the two compared.

| Kept | Replaced |
| --- | --- |
| `specs/` (vision, PRD, feature specs) | `src/` |
| `uat/features/` (acceptance scenarios) | `docs/architecture/modules.json` and `generated/` |
| `docs/architecture/adr/` (history; a new ADR supersedes the structure) | stack setup, if the stack changes |
| the factory files | `uat/steps/` (step definitions bind scenarios to the new code) |

Run it in factory or design mode with the `dsf-rebuild` skill:

1. Agree what to try and what must be better, in numbers.
2. Branch `rebuild/<name>`; remove the old implementation on the branch only.
3. `dsf-architect` designs the new structure and writes a superseding ADR.
4. Build task by task until `make check` and `make uat` are green, with every `@critical` scenario passing.
5. The PR compares old and new: UAT pass rate, health metrics, size, performance. The human chooses.

What makes this work is writing acceptance scenarios against behaviour, not implementation: no class names, no URLs that only one design would have, no internal states.
