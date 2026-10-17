---
name: dsf-uat-interview
description: Interview the human to define user acceptance tests for a feature or the whole PRD, and write them as Gherkin scenarios in uat/features/. Use in design mode after the PRD exists, or when the human asks for acceptance tests.
---

# User acceptance test interview

User acceptance tests (UAT) are the human's definition of "done". Agents implement them later, in build mode, but never change them. Your job is to draw them out of the human, not to invent them.

## Before you start

1. Read `specs/vision.md`, `specs/prd.md` and any feature spec the human names.
2. List the user-visible behaviours the spec promises. Mark each one as covered, partly covered or not covered by existing files in `uat/features/`.

## Interview

- Ask one question at a time and wait for the answer. Offer a concrete example scenario with each question, so the human can correct it instead of writing from scratch.
- For each behaviour, ask for: the happy path, the most likely mistake a user makes, what must never happen, and any data or timing limits.
- Push back on vague answers ("it should be fast") until they are checkable ("the list of 1,000 items appears within 1 second").
- Stop when every behaviour in the spec has at least one scenario, or the human says to stop. Summarise what is still uncovered.

## Output

- One file per feature: `uat/features/<feature>.feature`, Gherkin (`Feature`, `Background`, `Scenario`, `Scenario Outline` with `Examples`).
- Each scenario has a tag linking it to the spec section: `@spec:prd#<section>`. Mark scenarios the human called critical with `@critical`.
- Use the user's words, not implementation details: no CSS selectors, class names or API paths.
- Create one task per feature file for build mode: "Implement UAT steps for <feature>", in the task backend named in `CLAUDE.app.md`.
- Commit with `uat: <feature> acceptance scenarios`. These files are protected in build mode, so they cannot be weakened to make code pass.

## Implementing them later (build mode, not this skill)

Step definitions live in `uat/steps/` and run with the stack's UAT runner (`make uat`; Playwright for desktop and web apps). A failing UAT scenario is fixed in the code, never in the `.feature` file.
