# Tasks

One Markdown file per task: `tasks/NNNN-short-slug.md`, numbered in creation order.
Agents and humans edit these files directly; git history is the audit trail.

Front matter fields:

```yaml
id: 0001
title: Short imperative title
status: todo        # todo | doing | blocked | done
type: feature       # feature | bug | arch-decision | dsf | research
spec: specs/prd.md#section
depends_on: []      # ids of tasks that must be done first
owner: agent        # agent | human
```

The body holds acceptance criteria as a checklist and links to ADRs or UAT scenarios.
An agent picks the lowest-numbered `todo` task whose `depends_on` are all `done`, sets it to `doing` in its first commit, and to `done` in the commit that completes it.
