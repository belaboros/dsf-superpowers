---
name: dsf-arch-health
description: Measure and explain the health of the architecture - cohesion, coupling, cycles, undeclared dependencies - with metrics and diagrams. Use when the human asks how healthy the architecture is, before an architecture review, or as the first step of dsf-arch-maintenance.
---

# Architecture health

1. Run `make arch-health`. It measures the real import graph against `docs/architecture/modules.json` and writes `arch/health/latest.md` and `latest.json` (previous runs are in `arch/health/history/`).
2. Read `latest.json` and the previous history entry. Explain, in plain words, for a human who has not read the code:
   - **Headline:** the overall trend (better, worse, same) with the two or three numbers that moved most.
   - **Coupling:** undeclared dependencies, module cycles and rule violations, each with the files that cause it (from `make arch-validate` output). Unstable modules that many others depend on (high Ca and high instability) are the riskiest.
   - **Cohesion:** modules whose cohesion (share of imports staying inside) is below 0.5 or falling, and what they import instead; large modules with low relational cohesion (< 1.0) are likely two modules.
   - **Hotspots:** files changed most in the last 30 days (`git log --since=30.days --name-only`) that also sit in weak modules.
3. Include the "Actual coupling" Mermaid diagram from `latest.md` and, when it differs, the intended one from `docs/architecture/generated/modules-coupling.mmd`, so the human can compare them side by side.
4. Do not propose fixes here unless asked; `dsf-arch-maintenance` does that.

Metric definitions are at the top of `scripts/dsf/arch/health.mjs`. Thresholds the app agreed on, if any, are in `docs/architecture/health-thresholds.json`.
