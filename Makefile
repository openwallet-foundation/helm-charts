###################################################################################################
# Makefile: OpenWallet Foundation Helm Charts                                                                      #
# Goal: Simple, readable developer ergonomics mirroring CI (see hack/versions.env for tool pins)  #
###################################################################################################

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.PHONY: help tools-check lint install test docs check _ensure-chart

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

# -------------------------------------------------------------------------------------------------
# Helper / internal targets
# -------------------------------------------------------------------------------------------------
_ensure-chart: # Internal: Validate CHART variable & path
	@if [ -z "$(CHART)" ]; then \
		echo "CHART variable required (e.g. make lint CHART=acapy)"; exit 1; \
	fi
	@if [ ! -d "$(CHART_PATH)" ]; then \
		echo "Chart directory $(CHART_PATH) not found"; exit 1; \
	fi

# -------------------------------------------------------------------------------------------------
# Help / meta
# -------------------------------------------------------------------------------------------------
help: ## List available targets with descriptions
	@echo "Available targets"; echo "-----------------"; \
	grep -hE '^[a-zA-Z0-9_.-]+:.*?##' $(MAKEFILE_LIST) | \
	  sed -E 's/^([a-zA-Z0-9_.-]+):.*?##\s*/\1: /' | \
	  awk -F': ' '{printf "% -$(HELP_COLUMNS)s %s\n", $$1, $$2}' | sort

# -------------------------------------------------------------------------------------------------
# Tooling / environment
# -------------------------------------------------------------------------------------------------
tools-check: ## Verify installed tool versions match pins (drift => fail)
	@bash hack/dev/tools-check.sh

# -------------------------------------------------------------------------------------------------
# Linting / formatting
# -------------------------------------------------------------------------------------------------
lint: _ensure-chart ## Lint chart with chart-testing (helm lint + yamllint + maintainers + version)
	@if [ ! -f .github/ct.yaml ]; then echo "Missing .github/ct.yaml config"; exit 1; fi
	@ct lint --charts $(CHART_PATH) --config .github/ct.yaml

# -------------------------------------------------------------------------------------------------
# Install tests
# -------------------------------------------------------------------------------------------------
install: _ensure-chart ## Run install test in ephemeral kind cluster
	@hack/chart/ct-install.sh "$(CHART)"

test: _ensure-chart ## Run full test suite: deps+lint+template+ct-install
	@hack/chart/local-test.sh "$(CHART)"

# -------------------------------------------------------------------------------------------------
# Documentation & Changelog
# -------------------------------------------------------------------------------------------------
docs: _ensure-chart ## Validate chart README is up-to-date
	@hack/chart/docs.sh "$(CHART)"

# -------------------------------------------------------------------------------------------------
# Check meta target (validation before PR)
# -------------------------------------------------------------------------------------------------
check: _ensure-chart ## Run all validations for CHART (lint + docs validation)
	@echo "[check] Running lint..."
	@$(MAKE) lint CHART=$(CHART) || exit 1
	@echo "[check] Validating README..."
	@$(MAKE) docs CHART=$(CHART) || exit 1
	@echo "[check] ✓ All checks passed"
