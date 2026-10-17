# TypeScript stack targets, called by the factory Makefile (make check, the edit hook, the pre-commit hook).
NPX := npx --no-install
SRC_FILES := $(shell find src -name '*.ts' 2>/dev/null | head -1)

.PHONY: check-stack typecheck lint test arch-validate duplication audit lint-file-stack precommit-stack uat

check-stack: typecheck lint test arch-validate duplication

typecheck:
	$(NPX) tsc --noEmit

lint:
	$(NPX) eslint --max-warnings 0 .

test:
	$(NPX) vitest run

arch-validate:
	@if [ -n "$(SRC_FILES)" ]; then $(NPX) depcruise src --config .dependency-cruiser.cjs; fi

duplication:
	@if [ -n "$(SRC_FILES)" ]; then $(NPX) jscpd src --threshold 5 --min-lines 8 --reporters consoleFull --silent; fi

# Advisory, not part of check: unused files, exports and dependencies.
audit:
	-$(NPX) knip

# Called by the PostToolUse hook for each edited file.
lint-file-stack:
	@case "$(FILE)" in \
	  *.ts|*.tsx|*.js|*.mjs|*.cjs) $(NPX) prettier --write --log-level warn "$(FILE)" && $(NPX) eslint --fix --no-warn-ignored --max-warnings 0 "$(FILE)" ;; \
	  *.json|*.md|*.yml|*.yaml) $(NPX) prettier --write --log-level warn "$(FILE)" ;; \
	esac

# Called by the git pre-commit hook: fast checks on staged files only.
precommit-stack:
	@files=$$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx|js|mjs|cjs)$$' || true); \
	if [ -n "$$files" ]; then $(NPX) prettier --check $$files && $(NPX) eslint --no-warn-ignored --max-warnings 0 $$files; fi

uat: ## run the acceptance scenarios (uat/features/*.feature with steps in uat/steps/); UAT=@critical for a subset
	@if ls uat/features/*.feature >/dev/null 2>&1; then $(NPX) bddgen && $(NPX) playwright test $(if $(UAT),--grep $(UAT)); else echo "No UAT scenarios yet."; fi
