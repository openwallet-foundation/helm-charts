###################################################################################################
# Makefile: OWF Helm Charts                                                                      #
# Goal: Simple, readable developer ergonomics mirroring CI (see hack/versions.env for tool pins)  #
###################################################################################################

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.PHONY: help tools-check lint ct-lint ct-install local-test docs changelog release-pr kind-delete _ensure-chart _cluster-name \
	sync-versions shell-lint shell-format shell-format-check fmt yamllint check verify test install-cli uninstall-cli act-pr actionlint act-release-publish

# -------------------------------------------------------------------------------------------------
# Core variables
# -------------------------------------------------------------------------------------------------
CHART           ?=
CHART_PATH       = charts/$(CHART)
VERSIONS_FILE    = hack/versions.env
HELP_COLUMNS     = 28

# Load version pins (export all uppercase names)
include $(VERSIONS_FILE)
export $(shell sed -n 's/^\([A-Z0-9_]*\)=.*/\1/p' $(VERSIONS_FILE))

# Discover shell scripts once (speeds up repeated targets)
SHELL_SOURCES   := $(shell find hack -type f -name '*.sh' 2>/dev/null)

# Shared formatting options for shfmt
SHFMT_OPTS      ?= -i 2 -ci -sr

# Shell lint strictness (set SHELL_LINT_STRICT=0 to not fail build on findings)
SHELL_LINT_STRICT ?= 1

# -------------------------------------------------------------------------------------------------
# Helper / internal targets
# -------------------------------------------------------------------------------------------------
_ensure-chart: ## (internal) Validate CHART variable & path
	@if [ -z "$(CHART)" ]; then \
		echo "CHART variable required (e.g. make lint CHART=acapy)"; exit 1; \
	fi
	@if [ ! -d "$(CHART_PATH)" ]; then \
		echo "Chart directory $(CHART_PATH) not found"; exit 1; \
	fi

_cluster-name: ## (internal) Echo deterministic kind cluster name
	@echo owf-$(CHART)-dev

# -------------------------------------------------------------------------------------------------
# Help / meta
# -------------------------------------------------------------------------------------------------
help: ## List available targets with descriptions
	@echo "Available targets"; echo "-----------------"; \
	grep -hE '^[a-zA-Z0-9_.-]+:.*?##' $(MAKEFILE_LIST) | \
	  sed -E 's/^([a-zA-Z0-9_.-]+):.*?##\s*/\1: /' | \
	  awk -F': ' '{printf "% -$(HELP_COLUMNS)s %s\n", $$1, $$2}' | sort

sync-versions: ## Show pinned versions file
	@echo "Versions pinned in $(VERSIONS_FILE):"; echo; sed 's/^/# /' $(VERSIONS_FILE) | sed 's/^# #/#/'; echo

# -------------------------------------------------------------------------------------------------
# Tooling / environment
# -------------------------------------------------------------------------------------------------
tools-check: ## Verify installed tool versions match pins (drift => fail)
	@bash hack/dev/tools-check.sh

# -------------------------------------------------------------------------------------------------
# Linting / formatting
# -------------------------------------------------------------------------------------------------
lint: _ensure-chart ## Helm lint for CHART
	helm lint $(CHART_PATH)

ct-lint: _ensure-chart ## chart-testing lint for CHART
	@if [ ! -f .github/ct.yaml ]; then echo "Missing .github/ct.yaml config"; exit 1; fi
	ct lint --charts $(CHART_PATH) --config .github/ct.yaml

shell-lint: ## Run shellcheck (SHELL_LINT_STRICT=0 to only warn)
	@if [ -z "$(SHELL_SOURCES)" ]; then echo "No shell scripts found"; exit 0; fi; \
	echo "[shell-lint] scanning $$(( $$(echo "$(SHELL_SOURCES)" | wc -w) )) scripts"; \
	set -o pipefail; shellcheck -S style -o all $(SHELL_SOURCES) | tee /tmp/.shellcheck.out; rc=$$?; \
	if [ $$rc -ne 0 ]; then \
	  if [ "$(SHELL_LINT_STRICT)" = "1" ]; then \
	    echo "[shell-lint] FAIL (strict mode)" >&2; exit 1; \
	  else \
	    echo "[shell-lint] WARN (non-strict: not failing build; set SHELL_LINT_STRICT=1 to enforce)"; exit 0; \
	  fi; \
	else \
	  echo "[shell-lint] OK"; \
	fi

shell-format: ## Format shell scripts via shfmt (idempotent)
	@if [ -z "$(SHELL_SOURCES)" ]; then echo "No shell scripts found"; exit 0; fi; \
	shfmt $(SHFMT_OPTS) -w $(SHELL_SOURCES)

shell-format-check: ## Diff-only shell formatting check (fails if changes needed)
	@if [ -z "$(SHELL_SOURCES)" ]; then echo "No shell scripts found"; exit 0; fi; \
	out=$$(shfmt $(SHFMT_OPTS) -d $(SHELL_SOURCES)); if [ -n "$$out" ]; then \
	  echo "[shell-format-check] Formatting issues detected:"; echo "$$out"; \
	  echo "[shell-format-check] To apply fixes: make shell-format"; exit 1; \
	else \
	  echo "[shell-format-check] OK"; \
	fi

fmt: shell-format ## Format all sources (alias of shell-format)

yamllint: _ensure-chart ## Lint chart YAML (ignores templates for now)
	@if command -v yamllint >/dev/null 2>&1; then \
	  yamllint -c .yamllint $(CHART_PATH); \
	else \
	  echo "yamllint not installed; install with: pip install --user yamllint"; \
	  exit 1; \
	fi

# -------------------------------------------------------------------------------------------------
# Install tests
# -------------------------------------------------------------------------------------------------
ct-install: _ensure-chart ## Run ct install test in ephemeral kind cluster
	@hack/chart/ct-install.sh "$(CHART)"

test: ct-install ## Alias for install test

local-test: _ensure-chart ## Run local CI-like test: deps+lint+template+ct-install
	@hack/chart/local-test.sh "$(CHART)"

# -------------------------------------------------------------------------------------------------
# Documentation & Changelog
# -------------------------------------------------------------------------------------------------
docs: _ensure-chart ## Regenerate chart README (Bitnami or helm-docs fallback)
	@hack/chart/docs.sh "$(CHART)"

changelog: _ensure-chart ## Update CHANGELOG (scoped commits & tag prefix)
	@hack/chart/changelog.sh "$(CHART)"

# -------------------------------------------------------------------------------------------------
# Release scaffolding (manual convenience; CI automation preferred)
# -------------------------------------------------------------------------------------------------
release-pr: _ensure-chart ## Compute next semver, update docs + changelog, open PR
	@hack/chart/release-pr.sh "$(CHART)"

# -------------------------------------------------------------------------------------------------
# Developer CLI shims
# -------------------------------------------------------------------------------------------------
install-cli: ## Install user-local shims (~/.local/bin) to run helpers anywhere
	@bash hack/dev/install-cli.sh

uninstall-cli: ## Remove installed user-local shims
	@bash hack/dev/uninstall-cli.sh

# -------------------------------------------------------------------------------------------------
# Check meta target (validation before PR)
# -------------------------------------------------------------------------------------------------
check: _ensure-chart ## Run all validations for CHART (lint suite + formatting)
	@echo "[check] tools-check"; $(MAKE) tools-check >/dev/null || exit 1; \
	echo "[check] shell-lint"; $(MAKE) shell-lint SHELL_LINT_STRICT=1 || exit 1; \
	echo "[check] shell-format-check"; $(MAKE) shell-format-check || exit 1; \
	echo "[check] yamllint"; $(MAKE) yamllint || exit 1; \
	echo "[check] helm lint"; $(MAKE) lint CHART=$(CHART) || exit 1; \
	if [ -f .github/ct.yaml ]; then echo "[check] ct lint"; $(MAKE) ct-lint CHART=$(CHART) || exit 1; else echo "[check] skip ct-lint (no .github/ct.yaml)"; fi; \
	echo "[check] done"

verify: check ## Alias for 'make check' (deprecated, will be removed)

# -------------------------------------------------------------------------------------------------
# Local workflow testing (optional; requires 'act')
# -------------------------------------------------------------------------------------------------
act-pr: ## Run PR workflow locally with act (override chart via DETECT_CHART=acapy)
	@if command -v act >/dev/null 2>&1; then \
	  DETECT_CHART=$(CHART) act pull_request -j lint-test -W .github/workflows/ci-cd.yaml --container-architecture linux/amd64; \
	else \
	  echo "act not found on PATH. In the devcontainer, it's preinstalled; try rebuilding the container."; exit 1; \
	fi


act-release-publish: ## Dry-run the Publish workflow locally
	@if command -v act >/dev/null 2>&1; then \
	  act workflow_dispatch -W .github/workflows/release-publish.yaml -j publish -s GITHUB_TOKEN=dummy --input dry_run=true --container-architecture linux/amd64; \
	else \
	  echo "act not found on PATH. In the devcontainer, it's preinstalled; try rebuilding the container."; exit 1; \
	fi

install-act: ## (deprecated) act is installed via devcontainer pins
	@echo "act is installed via devcontainer. Rebuild the container to (re)install pinned version."

actionlint: ## Run actionlint against workflows
	@actionlint -color
`
