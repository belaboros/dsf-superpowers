---
name: dsf-arch-maintenance
description: Scheduled architecture maintenance - check module health, explain findings with metrics and diagrams, and propose alternative designs (patterns, styles, module moves) for the human to decide. Use when run by the weekly dsf-arch-maintenance workflow or when the human asks for an architecture check-up.
---

# Architecture maintenance

You keep the module structure healthy over time. You propose; the human decides. Never change module boundaries without an accepted decision.

## 1. Measure and explain

Run the `dsf-arch-health` skill. Keep its explanation as the first section of your proposal.

## 2. Pick at most three problems

Rank findings by risk: cycles and undeclared dependencies first, then falling cohesion in modules with recent churn, then everything else. Skip anything already covered by an open `type:arch-decision` task.

## 3. Propose alternatives for each problem

Give two or three options, always including "leave as is". For each option state: what changes (modules, files, dependencies), the pattern it uses, the expected effect on the metrics (which numbers move and roughly how), the effort (number of files touched), and the risk. Useful moves:

- **Break a cycle:** dependency inversion (the stable module defines an interface, the other implements it), an event or observer, or moving the shared concept into a new lower-level module.
- **Raise cohesion:** split a module along the two responsibilities that change separately; move functions to the module whose data they use (feature envy); merge two modules that always change together.
- **Lower coupling:** a facade or narrower public API; an anti-corruption layer around an external or legacy part; ports and adapters at technology boundaries.
- **Architectural styles** when the problem is systemic: layered, hexagonal, pipes and filters, plugin architecture, event-driven, modular monolith.

Recommend one option and say why, but present the others fairly.

## 4. Hand the decision to the human

- Write `docs/architecture/proposals/<YYYY-MM-DD>-<topic>.md` from `.dsf/templates/proposal.md`, with the diagrams (current and proposed, Mermaid).
- Create one task of type `arch-decision` (label `status:needs-human` on GitHub) per problem, linking the proposal. Commit on a branch and open a PR so the proposal can be reviewed and commented on.
- After the human decides: write an ADR (superseding the old one if needed), update `modules.json`, run `make arch-rules`, and create the refactoring tasks. Refactoring happens in build mode in small steps, with `make check` green after each.
- If the human rejects an option, record it in the proposal under "Decision" with the reason, and do not propose the same option again unless the metrics that motivated it get worse.
