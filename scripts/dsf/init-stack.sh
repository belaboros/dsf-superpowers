#!/usr/bin/env bash
# init-stack.sh <stack>: add a language stack (tooling, linters, test runner) to an application.
# Copies .dsf/templates/stacks/<stack>/ into the repo without overwriting files, then installs dependencies.
# Available stacks: the folder names in .dsf/templates/stacks/.
set -euo pipefail
stack="${1:-typescript}"
root="$(git rev-parse --show-toplevel)"
src="$root/.dsf/templates/stacks/$stack"
[[ -d "$src" ]] || { echo "Unknown stack '$stack'. Available: $(ls "$root/.dsf/templates/stacks" | tr '\n' ' ')" >&2; exit 1; }
app="$(sed -n 's/^APP_NAME=//p' "$root/.dsf.app" 2>/dev/null || true)"
app="${app:-$(basename "$root")}"

cd "$src"
find . -type f | while read -r f; do
  dst="$root/${f#./}"
  if [[ -e "$dst" ]]; then echo "keep     ${f#./} (exists)"; continue; fi
  mkdir -p "$(dirname "$dst")"
  sed "s/{{APP_NAME}}/$app/g" "$f" > "$dst"
  echo "add      ${f#./}"
done
cd "$root"
if [[ -f package.json ]]; then npm install --no-fund --no-audit; fi
echo "Stack '$stack' ready. Run 'make check'."
