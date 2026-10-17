#!/usr/bin/env bash
# cloneForApplication.sh: start a new application from this dsf-* factory repo.
#
# Usage:
#   ./cloneForApplication.sh <app-name> [options]
#
# Options:
#   --dir PATH         where to create the application repo (default: ../<app-name> next to this repo)
#   --from URL         parent dsf-* repo to clone (default: this repo's 'origin' remote)
#   --origin URL       existing EMPTY application repo to push to
#   --create-github    create a private GitHub repo <owner>/<app-name> with the gh CLI and push to it
#   --owner NAME       GitHub owner for --create-github (default: your gh login)
#   --tasks BACKEND    where tasks live: markdown | backlog | beads | github
#                      (asked interactively when omitted; 'markdown' when not interactive)
#   --arch-review WHEN when the human reviews architecture: before (implementation waits) | after (review merged changes)
#                      (default: before)
#   --stack NAME       add a language stack now: typescript | none (default: none; the architect agent picks it later)
#   -h, --help         show this help
#
# Result:
#   remote 'dsf'     -> the parent factory repo (pull updates, contribute generic improvements)
#   remote 'origin'  -> the application repo (when --origin or --create-github is given)
#   branch 'main'    -> shares history with the parent, so factory updates merge cleanly
#   .dsf.app         -> this application's factory settings, including the task backend
#   git hooks        -> .dsf/githooks (keeps generic and app changes in separate commits)
set -euo pipefail

usage() { sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; }
die() { echo "cloneForApplication: $*" >&2; exit 1; }
say() { echo "==> $*"; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

app="" dir="" from="" origin="" create_github=0 owner="" tasks="" arch_review="before" stack="none"
while (( $# )); do
  case "$1" in
    --dir) dir="${2:?--dir needs a value}"; shift 2 ;;
    --from) from="${2:?--from needs a value}"; shift 2 ;;
    --origin) origin="${2:?--origin needs a value}"; shift 2 ;;
    --create-github) create_github=1; shift ;;
    --owner) owner="${2:?--owner needs a value}"; shift 2 ;;
    --tasks) tasks="${2:?--tasks needs a value}"; shift 2 ;;
    --arch-review) arch_review="${2:?--arch-review needs a value}"; shift 2 ;;
    --stack) stack="${2:?--stack needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $1 (see --help)" ;;
    *) [[ -z "$app" ]] || die "only one app name expected"; app="$1"; shift ;;
  esac
done

[[ -n "$app" ]] || { usage; exit 1; }
[[ "$app" =~ ^[A-Za-z0-9._-]+$ ]] || die "app name may only contain letters, digits, '.', '_' and '-'"
[[ -n "$origin" && $create_github -eq 1 ]] && die "use either --origin or --create-github, not both"
[[ "$arch_review" == before || "$arch_review" == after ]] || die "--arch-review must be 'before' or 'after'"
if [[ ! -f "$script_dir/.dsf.layer" ]]; then
  echo "Note: $script_dir is not a dsf-* workflow repo (no .dsf.layer); the app gets the base factory without a skill pack." >&2
fi

if [[ -z "$from" ]]; then
  from="$(git -C "$script_dir" remote get-url origin 2>/dev/null)" \
    || die "cannot find this repo's origin remote; pass --from <parent repo URL>"
fi
[[ -n "$dir" ]] || dir="$(dirname "$script_dir")/$app"
[[ ! -e "$dir" ]] || die "$dir already exists"

# --- Task backend: decided once, here --------------------------------------
backends=(markdown backlog beads github)
describe_backend() {
  case "$1" in
    markdown) echo "plain Markdown files in tasks/, no extra tools" ;;
    backlog)  echo "Backlog.md: Markdown tasks in backlog/ with a CLI, Kanban board and MCP server" ;;
    beads)    echo "Beads (bd): git-backed, dependency-aware issue tracker built for coding agents" ;;
    github)   echo "GitHub Issues on the application repo, worked with the gh CLI" ;;
  esac
}
if [[ -z "$tasks" ]]; then
  if [[ -t 0 ]]; then
    echo "Where should tasks and tickets for $app live? (decided once, stored in .dsf.app)"
    i=1; for b in "${backends[@]}"; do printf '  %d) %-9s %s\n' "$i" "$b" "$(describe_backend "$b")"; i=$((i+1)); done
    read -r -p "Choose 1-${#backends[@]} [1]: " choice
    choice="${choice:-1}"
    [[ "$choice" =~ ^[1-4]$ ]] || die "invalid choice '$choice'"
    tasks="${backends[$((choice-1))]}"
  else
    tasks="markdown"
  fi
fi
case "$tasks" in markdown|backlog|beads|github) ;; *) die "unknown task backend '$tasks' (markdown, backlog, beads, github)";; esac
if [[ "$tasks" == github && -z "$origin" && $create_github -eq 0 ]]; then
  die "--tasks github needs a GitHub application repo: add --create-github or --origin <url>"
fi

# --- Clone ------------------------------------------------------------------
say "Cloning factory $from into $dir"
git clone --quiet --origin dsf "$from" "$dir"
cd "$dir"
parent_branch="$(git symbolic-ref --quiet --short refs/remotes/dsf/HEAD 2>/dev/null | sed 's#^dsf/##')"
parent_branch="${parent_branch:-main}"
git switch --quiet -C main "dsf/$parent_branch"
git branch --quiet --unset-upstream 2>/dev/null || true
parent_commit="$(git rev-parse HEAD)"

# Hooks and the helper must work in the new repo.
[[ -x scripts/dsf/dsf-sync.sh ]] || die "parent repo has no scripts/dsf/dsf-sync.sh; is it a dsf-* repo?"
git config core.hooksPath .dsf/githooks

# --- Application files --------------------------------------------------------
case "$tasks" in
  markdown) tasks_hint="One file per task in \`tasks/\`; see \`tasks/README.md\` for the format." ;;
  backlog)  tasks_hint="Use the \`backlog\` CLI or its MCP server (\`backlog mcp start\`); tasks are Markdown files in \`backlog/\`." ;;
  beads)    tasks_hint="Use the \`bd\` CLI: \`bd ready --json\` lists unblocked work, \`bd update <id> --claim\` takes a task." ;;
  github)   tasks_hint="Use \`gh issue list/create/close\` on the application repo; labels \`type:*\` and \`status:*\` drive the workflow." ;;
esac

say "Writing application files"
cat > .dsf.app <<EOF
# Dark / gray Software Factory settings for this application. Written once by cloneForApplication.sh.
APP_NAME=$app
ROLE=application
PARENT_URL=$from
PARENT_BRANCH=$parent_branch
PARENT_COMMIT=$parent_commit
TASKS_BACKEND=$tasks
ARCH_REVIEW=$arch_review
STACK=$stack
CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

if [[ $create_github -eq 1 && -z "$owner" ]] && command -v gh >/dev/null 2>&1; then owner="$(gh api user --jq .login 2>/dev/null || true)"; fi
if [[ -z "$owner" && -n "$origin" ]]; then owner="$(sed -E 's#^(git@github.com:|https://github.com/)##; s#/.*##' <<<"$origin")"; fi
owner="${owner:-OWNER}"

render() { # copy a template file, filling placeholders; never overwrite
  local src="$1" dst="$2"
  [[ -e "$dst" ]] && return 0
  mkdir -p "$(dirname "$dst")"
  APP="$app" PARENT="$from" TASKS="$tasks" HINT="$tasks_hint" OWNER="$owner" REVIEW="$arch_review" perl -pe '
    s/\{\{APP_NAME\}\}/$ENV{APP}/g; s/\{\{PARENT_URL\}\}/$ENV{PARENT}/g;
    s/\{\{TASKS_BACKEND\}\}/$ENV{TASKS}/g; s/\{\{TASKS_HINT\}\}/$ENV{HINT}/g;
    s/\{\{OWNER\}\}/$ENV{OWNER}/g; s/\{\{ARCH_REVIEW\}\}/$ENV{REVIEW}/g' "$src" > "$dst"
}
# App-owned files ("=" in dsf.paths) are replaced by the app version.
if [[ -d .dsf/templates/app-owned ]]; then
  while IFS= read -r -d '' f; do
    dst="${f#.dsf/templates/app-owned/}"; rm -f "$dst"; render "$f" "$dst"
  done < <(find .dsf/templates/app-owned -type f -print0)
fi
scripts/dsf/dsf-sync.sh setup-merge
# Workflow templates first: render never overwrites, so they take precedence over the base ones.
for t in workflow-app app; do
  [[ -d ".dsf/templates/$t" ]] || continue
  while IFS= read -r -d '' f; do
    render "$f" "${f#.dsf/templates/$t/}"
  done < <(find ".dsf/templates/$t" -type f -print0)
done

# --- Task backend setup ---------------------------------------------------------
next_steps=()
case "$tasks" in
  markdown)
    mkdir -p tasks
    for f in .dsf/templates/tasks/markdown/*; do [[ -e "$f" ]] && render "$f" "tasks/$(basename "$f")"; done ;;
  backlog)
    next_steps+=("Install Backlog.md (npm i -g backlog.md) and run: backlog init \"$app\"") ;;
  beads)
    next_steps+=("Install Beads (bd) and run: bd init") ;;
  github) ;; # labels are created after the GitHub repo exists
esac

# Language stack (optional now; the architect agent can add it later with make init-stack).
if [[ "$stack" != none ]]; then
  say "Adding the $stack stack"
  scripts/dsf/init-stack.sh "$stack"
fi
node scripts/dsf/build-settings.mjs >/dev/null

git add -A
git commit --quiet -m "app: start $app from Dark Software Factory ${from##*/} @ ${parent_commit:0:7}"

# --- Application remote -----------------------------------------------------------
if (( create_github )); then
  command -v gh >/dev/null 2>&1 || die "--create-github needs the gh CLI (https://cli.github.com)"
  [[ -n "$owner" ]] || owner="$(gh api user --jq .login)"
  say "Creating private GitHub repo $owner/$app"
  gh repo create "$owner/$app" --private --source . --remote origin --push >/dev/null
  git branch --quiet --set-upstream-to=origin/main main
elif [[ -n "$origin" ]]; then
  say "Pushing to $origin"
  git remote add origin "$origin"
  git push --quiet -u origin main
else
  next_steps+=("Create an empty repo for $app, then: git remote add origin <url> && git push -u origin main")
fi

if [[ "$tasks" == github ]]; then
  if command -v gh >/dev/null 2>&1; then
    say "Creating task labels on the application repo"
    repo="$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
    while IFS='|' read -r name color desc; do
      gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force >/dev/null || true
    done <<'LABELS'
type:feature|1d76db|New behaviour from the spec
type:bug|d73a4a|Something does not match the spec
type:arch-decision|5319e7|Needs an architecture decision from a human
type:dsf|0e8a16|Generic factory improvement to contribute to the parent
type:research|fbca04|Research or prototype before deciding
status:ready|c2e0c6|Unblocked and ready for an agent
status:needs-human|e99695|Waiting for a human review or decision
LABELS
  else
    next_steps+=("Install gh and create the type:* and status:* labels listed in cloneForApplication.sh")
  fi
fi

# --- Summary ------------------------------------------------------------------------
echo
say "Done: $dir"
echo "    remotes: $(git remote | tr '\n' ' ')"
echo "    tasks:   $tasks ($(describe_backend "$tasks"))"
echo "    factory updates:  scripts/dsf/dsf-sync.sh pull"
echo "    send back generic improvements: scripts/dsf/dsf-sync.sh contribute <topic>"
if (( ${#next_steps[@]} )); then
  echo "Next steps:"
  for s in "${next_steps[@]}"; do echo "    - $s"; done
fi
