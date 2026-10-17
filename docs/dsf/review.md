# Review

## What the human reviews

| What | When | Where |
| --- | --- | --- |
| Vision | at the start | `specs/vision.md` |
| PRD and UAT scenarios | after the interviews | PR with `specs/` and `uat/features/` |
| Architecture | before build (`ARCH_REVIEW=before`) or after merge (`after`) | PR labelled `type:arch-decision` |
| Weekly proposals | Monday | PRs from `dsf-arch-maintenance` and `dsf-factory-improve` |
| Code | each PR, after CI and the review agent | the PR |

`.github/CODEOWNERS` makes specs, acceptance scenarios, architecture and factory files need your approval, so an agent cannot change the contract or the factory without you.

## The code review agent

Recommended: yes. Agents are good at noticing problems in code they did not write, and bad at noticing them in their own. `dsf-code-reviewer` runs with a fresh context, sees only the diff and the documents that define correct behaviour, and reports graded findings (`blocking`, `should-fix`, `note`). It never edits or approves.

It runs twice: locally before the PR is opened, and in GitHub Actions on every PR (`dsf-code-review.yml`, once the agents are enabled). It catches what the deterministic checks cannot: spec mismatches, tests that assert nothing, responsibility in the wrong module. When it finds something a rule could catch, it says so, and `dsf-factory-improve` turns repeats into rules. Over time the reviewer covers less, because the linters cover more.

Its precision (findings you accepted / all findings) is measured weekly; noisy reviewers get ignored, so its instructions are tuned on that number.

## The architecture review agent

`dsf-arch-reviewer` checks architecture PRs: every module has one responsibility, dependencies form a DAG toward the stable core, every decision names its ASR, and ADRs list rejected options. It prepares the human's decision; it does not make it.

## Reviewing quickly

- Start with the PR summary and the checklist from the PR template.
- For architecture, read the ADR and the two diagrams before any code.
- For code, read the tests first: they say what the change claims to do.
