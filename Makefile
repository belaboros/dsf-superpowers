# Dark / grey Software Factory: entry points for humans, agents, hooks and CI.
# Layers add targets in Makefile.workflow (dsf-* repo) and Makefile.app (application stack).
-include Makefile.workflow
-include Makefile.app

SHELL := /bin/bash
has-target = $(shell $(MAKE) -n $(1) >/dev/null 2>&1 && echo yes)

.PHONY: help check precommit settings settings-check arch-rules arch-check arch-health \
        design build factory init-stack sync-status sync-pull contribute

help: ## list targets
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/' | sort

check: settings-check arch-check ## everything an agent must pass before finishing (Stop hook, CI)
	@if [ "$(call has-target,check-stack)" = yes ]; then $(MAKE) --no-print-directory check-stack; fi
	@if [ "$(call has-target,check-workflow)" = yes ]; then $(MAKE) --no-print-directory check-workflow; fi
	@echo "make check: all green"

precommit: ## fast checks on staged files (git pre-commit hook)
	@if [ "$(call has-target,precommit-stack)" = yes ]; then $(MAKE) --no-print-directory precommit-stack; fi

settings: ## rebuild .claude/settings.json from .dsf/settings/*.json
	@node scripts/dsf/build-settings.mjs

settings-check:
	@node scripts/dsf/build-settings.mjs --check

arch-rules: ## regenerate module rules and diagrams from docs/architecture/modules.json
	@node scripts/dsf/arch/modules.mjs gen

arch-check:
	@node scripts/dsf/arch/modules.mjs --check

arch-health: ## measure cohesion and coupling, write arch/health/latest.md
	@node scripts/dsf/arch/health.mjs

design: ## start Claude in design mode (interviews, specs, architecture; no production code)
	DSF_MODE=design claude

build: ## start Claude in build mode (code and tests; specs and architecture are read-only)
	DSF_MODE=build claude

factory: ## start Claude in factory mode (improve skills, hooks, rules, CI)
	DSF_MODE=factory claude

init-stack: ## add a language stack: make init-stack STACK=typescript
	@scripts/dsf/init-stack.sh $(or $(STACK),typescript)

sync-status: ## parent updates and local commits that could go back to the parent
	@scripts/dsf/dsf-sync.sh status

sync-pull: ## merge the parent's latest factory
	@scripts/dsf/dsf-sync.sh pull

contribute: ## send parent-owned commits back: make contribute TOPIC=better-rules
	@scripts/dsf/dsf-sync.sh contribute $(TOPIC)
