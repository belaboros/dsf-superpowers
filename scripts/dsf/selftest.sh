#!/usr/bin/env bash
# selftest.sh: end-to-end test of the factory chain in a temporary folder, without GitHub.
#
#   scripts/dsf/selftest.sh [--keep]
#
# Builds base -> workflow -> application from this repo's committed HEAD and checks that
# cloning, the mixed-commit guard, contributing up (two hops) and pulling down all work.
set -euo pipefail

keep=0; [[ "${1:-}" == --keep ]] && keep=1
src="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d)"
(( keep )) || trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-dsf-selftest}" GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-selftest@example.invalid}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export PATH="$tmp/bin:$PATH"; mkdir -p "$tmp/bin"; printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/gh"; chmod +x "$tmp/bin/gh"  # never call GitHub

pass=0
ok() { pass=$((pass+1)); echo "  ok  $*"; }
fail() { echo "FAIL  $*" >&2; exit 1; }
q() { "$@" >/dev/null 2>&1; }

echo "selftest in $tmp"

# --- base ---------------------------------------------------------------------
git clone --quiet --bare "$src" "$tmp/base.git"
git -C "$tmp/base.git" update-ref refs/heads/main "$(git -C "$src" rev-parse HEAD)"   # test what is checked out
git -C "$tmp/base.git" symbolic-ref HEAD refs/heads/main

# --- workflow -------------------------------------------------------------------
git init --quiet --bare -b main "$tmp/wf.git"
git clone --quiet "$tmp/wf.git" "$tmp/wf" 2>/dev/null
(cd "$tmp/wf" && "$src/scripts/dsf/new-workflow.sh" test --base "$tmp/base.git" >/dev/null && git push --quiet -u origin main 2>/dev/null)
[[ "$(cd "$tmp/wf" && scripts/dsf/dsf-sync.sh mode)" == workflow ]] && ok "workflow repo created on top of base" || fail "workflow mode"

# --- application ------------------------------------------------------------------
"$tmp/wf/cloneForApplication.sh" app --dir "$tmp/app" --from "$tmp/wf.git" --tasks markdown </dev/null >/dev/null
cd "$tmp/app"
[[ "$(scripts/dsf/dsf-sync.sh mode)" == application && -f .dsf.app && -f tasks/README.md ]] && ok "application cloned" || fail "application clone"
[[ "$(git config core.hooksPath)" == .dsf/githooks ]] && ok "git hooks installed" || fail "hooksPath"
grep -q '^# app' README.md && ok "application README replaces the factory README" || fail "app README"
make -s check >/dev/null && ok "make check is green in a fresh app" || fail "make check in fresh app"

# --- guards -----------------------------------------------------------------------
echo "x" >> docs/dsf/README.md; echo "x" >> specs/vision.md; git add -A
if git commit --quiet -m "chore: mixed" 2>/dev/null; then fail "mixed commit was accepted"; else ok "mixed commit refused"; fi
git reset --quiet --hard
echo "x" >> specs/vision.md
if git commit --quiet -am "no type prefix" 2>/dev/null; then fail "commit without type accepted"; else ok "commit message type enforced"; fi
git reset --quiet --hard

# --- contribute: app -> workflow ----------------------------------------------------------
echo "Selftest improvement." >> docs/dsf/review.md
git commit --quiet -am "dsf: selftest improvement"
echo "App change." >> specs/vision.md
git commit --quiet -am "spec: app change"
scripts/dsf/dsf-sync.sh contribute selftest >/dev/null 2>&1 || true
git -C "$tmp/wf.git" rev-parse --verify --quiet refs/heads/contrib/app/selftest >/dev/null && ok "contribute pushed contrib/app/selftest to the workflow repo" || fail "contribute to workflow"
[[ "$(git -C "$tmp/wf.git" diff --name-only main contrib/app/selftest)" == docs/dsf/review.md ]] && ok "only the factory commit went up" || fail "contribution content"

# merge it in the workflow repo (stands in for the PR)
cd "$tmp/wf"
git fetch --quiet origin
git merge --quiet --no-edit --no-ff origin/contrib/app/selftest
git push --quiet origin main

# --- contribute: workflow -> base ---------------------------------------------------------
scripts/dsf/dsf-sync.sh contribute selftest >/dev/null 2>&1 || true
git -C "$tmp/base.git" rev-parse --verify --quiet refs/heads/contrib/test/selftest >/dev/null && ok "second hop: workflow contributed to base" || fail "contribute to base"
git -C "$tmp/base.git" update-ref refs/heads/main refs/heads/contrib/test/selftest

# --- pull: base -> workflow -> app ---------------------------------------------------------
cd "$tmp/wf"
scripts/dsf/dsf-sync.sh pull >/dev/null
grep -q '^\*\*dsf-test\*\*' README.md && ok "workflow pull kept the workflow README" || fail "workflow README overwritten"
echo "Workflow note." >> docs/workflow/README.md
git commit --quiet -am "docs: workflow note"
git push --quiet origin main
cd "$tmp/app"
scripts/dsf/dsf-sync.sh pull >/dev/null
grep -q 'Workflow note.' docs/workflow/README.md && ok "app pulled the workflow update" || fail "app pull"
grep -q '^# app' README.md && ok "app pull kept the app README" || fail "app README after pull"
grep -q 'App change.' specs/vision.md && ok "app changes survive the pull" || fail "app change lost"
make -s check >/dev/null && ok "make check is green after the pull" || fail "make check after pull"

echo "selftest: $pass checks passed"
