# {{APP_NAME}}: architecture overview

Written and kept current by the architect agent (skill `dsf-architect`).

## Architecturally significant requirements (ASRs)

| ID | Requirement | Source (spec section) | Measure |
| --- | --- | --- | --- |

## Context (C4 level 1)

```mermaid
flowchart LR
  user([User]) --> app[{{APP_NAME}}]
```

## Modules

Module map: `modules.json`. Generated views: `generated/modules-cohesion.mmd` (responsibilities) and `generated/modules-coupling.mmd` (allowed dependencies). Actual health: `../../arch/health/latest.md`.

## Decisions

See `adr/`.
