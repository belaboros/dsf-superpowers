---
name: dsf-architect
description: Design or revise the application's architecture from the PRD - split it into modules with high cohesion and low coupling, write ADRs, draw component and dependency diagrams, and generate the enforceable module rules. Use in design mode after the PRD, before implementation, or when an architecture proposal was accepted.
---

# Architect

You turn the spec into a module structure that agents can build in and checks can enforce. Optimise for change: each module should have one reason to change, and dependencies should point toward the stable core.

## Inputs

`specs/vision.md`, `specs/prd.md`, `uat/features/`, existing `docs/architecture/` (modules, ADRs, health reports in `arch/health/`), and the `ARCH_REVIEW` setting in `.dsf.app` (`before` or `after`).

## Steps

1. **Quality attributes.** List the architecturally significant requirements (ASRs) from the PRD: performance, offline use, data safety, extensibility, platform. Write them in `docs/architecture/overview.md`; each later decision must name the ASR it serves.
2. **Module candidates.** Group capabilities by the business concept they change with (bounded contexts), not by technical layer. For each module write: name, single responsibility (one sentence, no "and"), data it owns, public API, and allowed dependencies.
3. **Check the split.** For each pair of modules ask whether a typical feature from the PRD would change both; if yes for most features, merge them or move the shared concept. Dependencies must form a directed acyclic graph that points from volatile (UI, adapters) to stable (domain). Prefer ports and adapters: the domain defines interfaces, adapters implement them.
4. **Stack.** If no stack is set up yet, pick one that fits the ASRs (default for desktop apps: TypeScript with Electron) and record it as an ADR. Run `make init-stack STACK=typescript` if that template fits.
5. **Write `docs/architecture/modules.json`** (format at the top of `scripts/dsf/arch/modules.mjs`). Paths must match where code will live (`src/<module>`), and `publicApi` is the only file other modules may import.
6. **ADRs.** One file per significant decision in `docs/architecture/adr/NNNN-title.md`, using `.dsf/templates/adr.md` (MADR). Include the options considered and why the others lost. Status starts as `proposed`.
7. **Diagrams.** Run `make arch-rules`. It writes `docs/architecture/generated/modules-cohesion.mmd` (what each module is for) and `modules-coupling.mmd` (allowed dependencies) plus the dependency-cruiser rules that enforce them. Add a C4 context and container diagram in Mermaid to `overview.md`; embed the generated diagrams there.
8. **Review.** Open a PR labelled `type:arch-decision` containing only `docs/architecture/**` (and stack setup files). If `ARCH_REVIEW=before`, implementation tasks wait until the human approves it; if `after`, mark the ADRs `accepted` and continue, and the weekly digest asks the human to confirm.
9. **Tasks.** Create implementation tasks per module in vertical slices that cut through the modules a feature needs, each linking the spec section and UAT scenarios.

## Rules

- Never write production code in this skill.
- Every module change after the first design goes through an ADR that supersedes the old one; never edit an accepted ADR's decision.
- If you cannot state a module's responsibility without "and", split it or explain in the ADR why not.
