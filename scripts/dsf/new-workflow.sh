#!/usr/bin/env bash
# new-workflow.sh: turn a fresh clone of an (empty) repo into a dsf-* workflow repo built on dsf-base.
#
#   scripts/dsf/new-workflow.sh <workflow-name> [--base URL] [--branch main]
#
# Run it from dsf-base, with the target repo as the current directory:
#   git clone https://github.com/<you>/dsf-myflow && cd dsf-myflow
#   ../dsf-base/scripts/dsf/new-workflow.sh myflow
#
# Result: remote 'base' -> dsf-base, dsf-base history merged in, .dsf.layer, and placeholder
# workflow files (README.md, .dsf/CLAUDE.workflow.md, .dsf/settings/workflow.json, docs/workflow/)
# committed. Fill them in for the skill pack, then push.
set -euo pipefail

die() { echo "new-workflow: $*" >&2; exit 1; }
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

name="" base_url="" branch="main"
while (( $# )); do
  case "$1" in
    --base) base_url="${2:?--base needs a value}"; shift 2 ;;
    --branch) branch="${2:?--branch needs a value}"; shift 2 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) name="$1"; shift ;;
  esac
done
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "usage: new-workflow.sh <workflow-name> [--base URL]"
[[ -n "$base_url" ]] || base_url="$(git -C "$script_dir" remote get-url origin)" || die "pass --base <dsf-base URL>"

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run it inside the new workflow repo"
cd "$root"
[[ ! -f .dsf.layer && ! -f .dsf.app ]] || die "this repo is already part of the factory chain"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean"

git remote get-url base >/dev/null 2>&1 || git remote add base "$base_url"
git fetch --quiet base "$branch"
if git rev-parse --verify --quiet HEAD >/dev/null; then
  # Files both repos start with (LICENSE, README) take dsf-base's version; README is replaced below.
  git merge --quiet --no-edit --allow-unrelated-histories -X theirs -m "dsf: build on dsf-base" "base/$branch"
else
  git reset --quiet --hard "base/$branch"
fi
git config core.hooksPath .dsf/githooks

cat > .dsf.layer <<LAYER
# Dark / grey Software Factory workflow layer. Parent: dsf-base.
ROLE=workflow
WORKFLOW_NAME=$name
BASE_URL=$base_url
BASE_BRANCH=$branch
LAYER
scripts/dsf/dsf-sync.sh setup-merge

head -n 3 README.md > README.md.new   # title and goal paragraph from dsf-base
cat >> README.md.new <<README
**dsf-$name** is a workflow repo: dsf-base plus a skill pack. Describe the pack and how its commands map to the factory's workflow steps here.

\`\`\`bash
./cloneForApplication.sh my-app --create-github --tasks github
\`\`\`

How the factory works: [docs/dsf/](docs/dsf/README.md). This workflow: [docs/workflow/](docs/workflow/README.md).
README
mv README.md.new README.md
printf '# Workflow layer: %s\n\nMap each factory workflow step (docs/dsf/workflows.md) to this skill pack'"'"'s commands.\n' "$name" > .dsf/CLAUDE.workflow.md
[[ -f .dsf/settings/workflow.json ]] || printf '{\n  "extraKnownMarketplaces": {},\n  "enabledPlugins": {}\n}\n' > .dsf/settings/workflow.json
mkdir -p docs/workflow
[[ -f docs/workflow/README.md ]] || printf '# dsf-%s workflow\n\nHow this skill pack is used in each workflow step.\n' "$name" > docs/workflow/README.md
node scripts/dsf/build-settings.mjs >/dev/null

git add -A
git commit --quiet -m "dsf: start workflow layer $name"
echo "Workflow repo dsf-$name is ready. Fill in README.md, .dsf/CLAUDE.workflow.md, .dsf/settings/workflow.json and docs/workflow/, then push."
