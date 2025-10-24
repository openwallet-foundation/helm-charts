#!/usr/bin/env bash
# docs.sh - Regenerate README for a chart using Bitnami generator (preferred) or helm-docs.
# Usage: docs.sh <chart>

set -Eeuo pipefail
# Resolve repo root relative to this script to avoid dependence on caller CWD
script_dir=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../lib/log.sh
# shellcheck disable=SC1091
source "${script_dir}/../lib/log.sh"
chart="${1:-}"
[[ -z "${chart}" ]] && die "Usage: $0 <chart>"
repo_root=$(cd "${script_dir}/../.." && pwd)
chart_dir="${repo_root}/charts/${chart}"
values_file="${chart_dir}/values.yaml"
readme_file="${chart_dir}/README.md"
[[ ! -d "${chart_dir}" ]] && die "chart dir missing: ${chart_dir}"
BITNAMI_README_GENERATOR_VERSION="${BITNAMI_README_GENERATOR_VERSION:-}"
pkg_name="@bitnami/readme-generator-for-helm"
if [[ -n "${BITNAMI_README_GENERATOR_VERSION}" ]]; then pkg_spec="${pkg_name}@${BITNAMI_README_GENERATOR_VERSION}"; else pkg_spec="${pkg_name}"; fi
if npx --yes --quiet "${pkg_spec}" --help > /dev/null 2>&1; then
  log_info "Using Bitnami readme generator via npx"
  npx --yes "${pkg_spec}" --readme "${readme_file}" --values "${values_file}"
elif command -v helm-docs > /dev/null 2>&1; then
  log_info "Fallback to helm-docs"
  helm-docs -c "${chart_dir}"
else
  die "No README generator installed (need @bitnami/readme-generator-for-helm or helm-docs)"
fi
