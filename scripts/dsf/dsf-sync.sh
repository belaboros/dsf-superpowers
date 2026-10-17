#!/usr/bin/env bash
# dsf-sync: keep a repo in sync with its parent in the factory chain
#
#   dsf-base  ->  dsf-<workflow>  ->  application
#
# Run it inside a workflow repo (parent = dsf-base, remote "base", ownership in base.paths)
# or inside an application repo (parent = its dsf-* repo, remote "dsf", ownership in dsf.paths).
#
#   scripts/dsf/dsf-sync.sh status                 parent updates not merged yet, local commits by kind
#   scripts/dsf/dsf-sync.sh pull                   merge the parent's latest main into the current branch
#   scripts/dsf/dsf-sync.sh contribute <topic>     send parent-owned commits back to the parent as a branch (+ PR)
#   scripts/dsf/dsf-sync.sh classify <path>...     print "up" (parent-owned) or "own" for each path
#   scripts/dsf/dsf-sync.sh check-staged           fail if staged changes mix parent-owned and own paths
#   scripts/dsf/dsf-sync.sh setup-merge            keep our version of "=" files when merging the parent
#   scripts/dsf/dsf-sync.sh mode                   print base, workflow or application
set -euo pipefail

die() { echo "dsf-sync: $*" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"

setting() { # setting <file> <key>
  [[ -f "$ROOT/$1" ]] || return 0
  sed -n "s/^$2=//p" "$ROOT/$1" | tail -n 1
}

# Which level of the chain this repo is, and who its parent is.
if [[ -f "$ROOT/.dsf.app" ]]; then
  MODE=application; REMOTE=dsf; PATHS_FILE=dsf.paths
  NAME="$(setting .dsf.app APP_NAME)"; BRANCH="$(setting .dsf.app PARENT_BRANCH)"
elif [[ -f "$ROOT/.dsf.layer" ]]; then
  MODE=workflow; REMOTE=base; PATHS_FILE=base.paths
  NAME="$(setting .dsf.layer WORKFLOW_NAME)"; BRANCH="$(setting .dsf.layer BASE_BRANCH)"
else
  MODE=base; REMOTE=""; PATHS_FILE=""; NAME=base; BRANCH=""
fi
REMOTE="${DSF_REMOTE:-$REMOTE}"
BRANCH="${DSF_BRANCH:-${BRANCH:-main}}"
NAME="${NAME:-unnamed}"

need_parent() {
  [[ "$MODE" != base ]] || die "this is dsf-base, the top of the chain; it has no parent"
}

# classify <path>: "up" when the parent owns the path, otherwise "own".
# Pattern rules are documented at the top of base.paths / dsf.paths.
classify() {
  local path="$1" result="own" line neg pat
  [[ -f "$ROOT/$PATHS_FILE" ]] || die "$PATHS_FILE not found"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    neg=0
    if [[ "$line" == !* || "$line" == =* ]]; then neg=1; line="${line:1}"; fi
    pat="$line"
    if [[ "$pat" == */ || "$pat" == *- ]]; then
      [[ "$path" == "$pat"* ]] || continue
    else
      [[ "$path" == "$pat" ]] || continue
    fi
    if (( neg )); then result="own"; else result="up"; fi
  done < "$ROOT/$PATHS_FILE"
  echo "$result"
}

# commit_kind <sha>: up, own or mixed, from the files the commit touches.
commit_kind() {
  local f up=0 own=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ "$(classify "$f")" == up ]]; then up=1; else own=1; fi
  done < <(git diff-tree --no-commit-id --name-only -r "$1")
  if (( up && own )); then echo mixed; elif (( up )); then echo up; else echo own; fi
}

fetch_parent() {
  git remote get-url "$REMOTE" >/dev/null 2>&1 || die "no '$REMOTE' remote; add it with: git remote add $REMOTE <parent repo url>"
  git fetch --quiet "$REMOTE" "$BRANCH"
}

require_clean() {
  [[ -z "$(git status --porcelain --untracked-files=no)" ]] || die "working tree has uncommitted changes; commit or stash them first"
}

# Files marked "=" exist in the parent but are owned here: a merge keeps our version.
setup_merge() {
  [[ -n "$PATHS_FILE" && -f "$ROOT/$PATHS_FILE" ]] || return 0
  local attrs line
  attrs="$(git rev-parse --git-path info/attributes)"
  mkdir -p "$(dirname "$attrs")"; touch "$attrs"
  git config merge.ours.driver true
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line%"${line##*[![:space:]]}"}"
    [[ "$line" == =* ]] || continue
    grep -qxF "/${line:1} merge=ours" "$attrs" || echo "/${line:1} merge=ours" >> "$attrs"
  done < "$ROOT/$PATHS_FILE"
}

cmd_classify() {
  need_parent
  local p
  for p in "$@"; do printf '%s\t%s\n' "$(classify "$p")" "$p"; done
}

cmd_check_staged() {
  [[ "$MODE" != base ]] || return 0
  local f up=() own=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ "$(classify "$f")" == up ]]; then up+=("$f"); else own+=("$f"); fi
  done < <(git diff --cached --name-only)
  if (( ${#up[@]} && ${#own[@]} )); then
    echo "dsf-sync: this commit mixes files owned by the parent ($PATHS_FILE) with files owned by this repo." >&2
    echo "  parent-owned: ${up[*]}" >&2
    echo "  own:          ${own[*]}" >&2
    echo "Commit them separately, so the parent-owned part can be sent back with 'scripts/dsf/dsf-sync.sh contribute <topic>'." >&2
    exit 1
  fi
}

cmd_status() {
  need_parent
  fetch_parent
  local base="$REMOTE/$BRANCH" sha
  echo "Mode: $MODE ($NAME). Parent: $(git remote get-url "$REMOTE") ($base at $(git rev-parse --short "$base"))"
  echo "Parent commits not merged here yet: $(git rev-list --count "HEAD..$base")"
  echo "Local commits not in the parent (up = can be contributed):"
  while IFS= read -r sha; do
    printf '  %-5s %s\n' "$(commit_kind "$sha")" "$(git log -1 --format='%h %s' "$sha")"
  done < <(git rev-list --reverse --no-merges "$base..HEAD")
}

regenerate_settings() {
  if [[ -f "$ROOT/scripts/dsf/build-settings.mjs" ]] && command -v node >/dev/null 2>&1; then
    node "$ROOT/scripts/dsf/build-settings.mjs" >/dev/null
    if [[ -n "$(git status --porcelain -- .claude/settings.json)" ]]; then
      git add .claude/settings.json
      git commit --quiet -m "dsf: regenerate .claude/settings.json after sync"
    fi
  fi
}

cmd_pull() {
  need_parent
  fetch_parent
  require_clean
  setup_merge
  local base="$REMOTE/$BRANCH"
  if git merge-base --is-ancestor "$base" HEAD; then
    echo "Already up to date with $base."
    return 0
  fi
  git merge --no-ff --no-edit -m "dsf: sync from parent $(git rev-parse --short "$base")" "$base"
  regenerate_settings
  echo "Merged $base. Run 'make check' before pushing."
}

cmd_contribute() {
  need_parent
  local topic="${1:-}"
  [[ -n "$topic" ]] || die "usage: dsf-sync contribute <topic>"
  [[ "$topic" =~ ^[A-Za-z0-9._-]+$ ]] || die "topic may only contain letters, digits, '.', '_' and '-'"
  fetch_parent
  require_clean

  local base="$REMOTE/$BRANCH" sha kind picks=() mixed=()
  while IFS= read -r sha; do
    kind="$(commit_kind "$sha")"
    case "$kind" in
      up) # skip changes the parent already has (for example contributed earlier)
          if git cherry "$base" "$sha" "$sha^" 2>/dev/null | grep -q '^+'; then picks+=("$sha"); fi ;;
      mixed) mixed+=("$sha") ;;
    esac
  done < <(git rev-list --reverse --no-merges "$base..HEAD")

  if (( ${#mixed[@]} )); then
    echo "Skipped commits that mix parent-owned and own files (split them to contribute the parent-owned part):" >&2
    for sha in "${mixed[@]}"; do echo "  $(git log -1 --format='%h %s' "$sha")" >&2; done
  fi
  (( ${#picks[@]} )) || { echo "Nothing to contribute: no parent-owned commits that the parent lacks."; return 0; }

  local current branch="dsf-contrib/$topic" remote_branch="contrib/$NAME/$topic"
  current="$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)"
  git switch --quiet -C "$branch" "$base"
  if ! git cherry-pick "${picks[@]}" >/dev/null; then
    git cherry-pick --abort || true
    git switch --quiet "$current"
    die "cherry-pick onto the parent failed because the parent changed the same files; run 'dsf-sync pull' first, then retry"
  fi
  git push --quiet -u "$REMOTE" "$branch:$remote_branch"
  git switch --quiet "$current"
  echo "Pushed ${#picks[@]} commit(s) to '$REMOTE' as branch $remote_branch."

  local url; url="$(git remote get-url "$REMOTE")"
  if command -v gh >/dev/null 2>&1 && [[ "$url" == *github.com* ]]; then
    local repo; repo="$(sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##' <<<"$url")"
    gh pr create --repo "$repo" --base "$BRANCH" --head "$remote_branch" \
      --title "dsf: $topic (from $NAME)" \
      --body "Factory improvements found in **$NAME**, sent with \`scripts/dsf/dsf-sync.sh contribute\`." \
      || echo "Could not open the PR automatically; open it on GitHub from branch $remote_branch."
  else
    echo "Open a pull request in the parent repo from branch $remote_branch into $BRANCH."
  fi
}

main() {
  local cmd="${1:-status}"; shift || true
  case "$cmd" in
    status) cmd_status ;;
    pull) cmd_pull ;;
    contribute) cmd_contribute "$@" ;;
    classify) cmd_classify "$@" ;;
    check-staged) cmd_check_staged ;;
    setup-merge) setup_merge ;;
    mode) echo "$MODE" ;;
    -h|--help|help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "unknown command '$cmd' (try --help)" ;;
  esac
}

main "$@"
