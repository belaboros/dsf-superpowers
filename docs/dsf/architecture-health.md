# Architecture health

Architecture is only maintained if it is measured. The factory keeps a declared architecture (what the architect decided) and measures the actual one (what the code does), every PR and every week.

## Declared: the module map

`docs/architecture/modules.json`, written by `dsf-architect`:

```json
{ "modules": [
  { "name": "core", "path": "src/core", "responsibility": "Domain rules", "publicApi": "src/core/index.ts", "dependsOn": [] },
  { "name": "ui",   "path": "src/ui",   "responsibility": "Screens",      "publicApi": "src/ui/index.ts",   "dependsOn": ["core"] }
] }
```

`make arch-rules` turns it into:

- `generated/depcruise-modules.cjs`: dependency-cruiser rules, enforced by `make check`. A module may import only the modules in its `dependsOn`, and only through their `publicApi` file.
- `generated/modules-cohesion.mmd`: what each module is responsible for.
- `generated/modules-coupling.mmd`: the allowed dependency graph.

`make check` fails when the generated files are older than `modules.json`.

## Actual: the health report

`make arch-health` reads the real import graph and writes `arch/health/latest.md` (for humans), `latest.json` (for agents) and a dated copy in `history/`.

| Metric | Meaning | Good direction |
| --- | --- | --- |
| cohesion | internal imports / (internal + outgoing) per module | up; below 0.5 the module mostly talks to others |
| relational cohesion | (internal edges + 1) / files | 1.5 to 4; below 1 the files barely relate |
| Ca / Ce | modules that use this one / modules it uses | Ce small for domain modules |
| instability | Ce / (Ca + Ce) | near 0 for the core, near 1 for UI and adapters; dependencies should point toward lower instability |
| undeclared | dependencies `modules.json` does not allow | 0 |
| rule violations | dependency-cruiser errors | 0 (CI fails otherwise) |
| module cycles | cycles between modules | 0 (CI fails otherwise) |
| cross-module share | share of all imports that cross a module boundary | down |

Each value shows its change since the last run, and the report includes a Mermaid diagram of the actual coupling, with undeclared edges marked.

## Weekly maintenance

`dsf-arch-maintenance` (GitHub Actions, Monday, design mode) runs the report and, when something drifted, opens a proposal PR in `docs/architecture/proposals/`:

1. **Finding**: the metric, its trend, and the diagram that shows it.
2. **Cause**: which files and imports produce it.
3. **Options**: two or three, each named by its pattern (for example move a concept, introduce a port and adapter, split by bounded context, facade, mediator, event-based decoupling), with the expected metric change and the cost.
4. **Recommendation**.

The human decides. An accepted proposal becomes an ADR and build tasks; a rejected one is recorded so the agent does not propose it again.
