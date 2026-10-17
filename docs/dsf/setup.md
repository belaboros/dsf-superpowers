# Setup

## Prerequisites on the laptop

| Tool | Why | Check |
| --- | --- | --- |
| git 2.40+ | everything | `git --version` |
| Node.js 20+ | hooks, settings builder, architecture scripts, TypeScript stack | `node --version` |
| Claude Code | the agents | `claude --version` |
| GitHub CLI `gh`, logged in | creating repos, PRs, issues, contributing back | `gh auth status` |
| make, bash, perl | entry points and scripts | usually preinstalled on macOS and Linux |
| gitleaks (optional) | secret scan in the pre-commit hook | `gitleaks version` |
| uv (dsf-speckit only) | runs the Spec Kit `specify` CLI | `uv --version` |

## Start an application

From a clone of the dsf-* repo you picked (not dsf-base, which has no workflow layer):

```bash
git clone https://github.com/belaboros/dsf-hybrid && cd dsf-hybrid
./cloneForApplication.sh my-app --create-github --tasks github --arch-review before --stack typescript
cd ../my-app
make design        # Claude in design mode: write specs/vision.md together, then the interviews
```

| Option | Values | Default |
| --- | --- | --- |
| `--tasks` | `markdown`, `backlog`, `beads`, `github` (see [tasks.md](tasks.md)) | asked; `markdown` when not interactive |
| `--arch-review` | `before` (human approves architecture before code) or `after` (human reviews after merge) | `before` |
| `--stack` | `typescript` or `none` (add one later with `make init-stack STACK=typescript`) | `none` |
| `--create-github` / `--origin URL` | where the application repo lives | no remote; you add one later |
| `--dir`, `--from`, `--owner` | target folder, parent URL, GitHub owner | next to the factory, its `origin`, your `gh` login |

The script writes `.dsf.app` (these choices, recorded once), sets `core.hooksPath` to `.dsf/githooks`, keeps the app's own README and CODEOWNERS on future factory merges, and makes the first commit.

**Plugins.** The first time Claude starts in the new repo it asks to trust the folder and to install the skill-pack plugins listed in `.claude/settings.json` (`extraKnownMarketplaces` and `enabledPlugins`). Accept both.

## Turn on the GitHub agents (optional, per repo)

The workflows in `.github/workflows/dsf-*.yml` run `make check` on every PR. The agent workflows (code review, weekly architecture maintenance, weekly factory improvement) stay off until you set them up:

1. Secret `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`, uses your Claude subscription) or `ANTHROPIC_API_KEY`. Settings → Secrets and variables → Actions.
2. Install the Claude GitHub app on the repo: run `/install-github-app` in Claude Code, or https://github.com/apps/claude.
3. Repository variable `DSF_AGENTS_ENABLED` = `true`.
4. For the weekly factory sync PR (`dsf-sync.yml`), a secret `DSF_PARENT_TOKEN`: a fine-grained token with read access to the parent repo. Not needed when the parent is public.

## Protect main

Settings → Branches → add a rule (or ruleset) for `main`:

- Require a pull request, with 1 approval and **Require review from Code Owners** (the app's `.github/CODEOWNERS` names you for specs, acceptance scenarios, architecture and factory files).
- Require status checks: `dsf-ci / check`.
- Block force pushes. Allow merge commits: factory sync PRs must be merged with a merge commit, never squashed, or the next sync conflicts.

The Claude Code hooks already refuse pushes to `main`, force pushes and `--no-verify`; branch protection makes the same rules hold for humans and CI.
