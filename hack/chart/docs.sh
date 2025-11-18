#!/usr/bin/env bash
# docs.sh - Validate that README is up-to-date with values.yaml annotations.
# Usage: docs.sh <chart>
# Exit 0 if README matches generated output, 1 if drift detected.

set -Eeuo pipefail
# Resolve repo root relative to this script to avoid dependence on caller CWD
script_dir=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../lib/log.sh
source "${script_dir}/../lib/log.sh"
chart="${1:-}"
[[ -z "${chart}" ]] && die "Usage: $0 <chart>"
repo_root=$(cd "${script_dir}/../.." && pwd)
chart_dir="${repo_root}/charts/${chart}"
values_file="${chart_dir}/values.yaml"
readme_file="${chart_dir}/README.md"
[[ ! -d "${chart_dir}" ]] && die "chart dir missing: ${chart_dir}"
[[ ! -f "${values_file}" ]] && die "values.yaml missing: ${values_file}"

# Detect which documentation tool to use based on values.yaml annotations
log_info "Detecting documentation format for ${chart}..."
doc_tool="none"

if grep -q "^## @param" "${values_file}"; then
  doc_tool="readme-generator"
  log_info "Detected readme-generator format (## @param annotations)"
elif grep -q "^# --" "${values_file}"; then
  doc_tool="helm-docs"
  log_info "Detected helm-docs format (# -- annotations)"
else
  log_warn "No documentation annotations found in values.yaml"
  log_warn "Consider adding '## @param' (readme-generator) or '# --' (helm-docs) annotations"
fi

# Generate README based on detected tool
if [[ "${doc_tool}" == "helm-docs" ]]; then
  if command -v helm-docs > /dev/null 2>&1; then
    log_info "Validating README with helm-docs"
    # Generate to temp dir and compare
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "${tmp_dir}"' EXIT

    # Copy chart to temp dir to generate README there
    cp -r "${chart_dir}" "${tmp_dir}/"
    chart_basename=$(basename "${chart_dir}")
    helm-docs -c "${tmp_dir}/${chart_basename}" > /dev/null 2>&1

    if ! diff -u "${readme_file}" "${tmp_dir}/${chart_basename}/README.md" > /dev/null 2>&1; then
      log_error "README drift detected for ${chart}"
      log_error "README is out of sync with values.yaml annotations"
      echo
      echo "Diff (current vs expected):"
      diff -u "${readme_file}" "${tmp_dir}/${chart_basename}/README.md" | head -100 || true
      echo
      log_error "To fix: helm-docs -c charts/${chart}"
      exit 1
    fi
    log_ok "README is up-to-date"
  else
    die "helm-docs not found. Install: go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest"
  fi
elif [[ "${doc_tool}" == "readme-generator" ]]; then
  BITNAMI_README_GENERATOR_VERSION="${BITNAMI_README_GENERATOR_VERSION:-}"
  pkg_name="@bitnami/readme-generator-for-helm"
  if [[ -n "${BITNAMI_README_GENERATOR_VERSION}" ]]; then
    pkg_spec="${pkg_name}@${BITNAMI_README_GENERATOR_VERSION}"
  else
    pkg_spec="${pkg_name}"
  fi

  if npx --yes --quiet "${pkg_spec}" --help > /dev/null 2>&1; then
    log_info "Validating README with Bitnami readme-generator"
    # Generate to temp file and compare
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "${tmp_dir}"' EXIT

    # Copy current README and values to temp dir
    cp "${readme_file}" "${tmp_dir}/README.md.current"
    cp "${readme_file}" "${tmp_dir}/README.md.generated"
    cp "${values_file}" "${tmp_dir}/values.yaml"

    # Generate fresh README (modifies in place)
    npx --yes "${pkg_spec}" --readme "${tmp_dir}/README.md.generated" --values "${tmp_dir}/values.yaml" > /dev/null 2>&1

    if ! diff -u "${tmp_dir}/README.md.current" "${tmp_dir}/README.md.generated" > /dev/null 2>&1; then
      log_error "README drift detected for ${chart}"
      log_error "README is out of sync with values.yaml annotations"
      echo
      echo "Diff (current vs expected):"
      diff -u "${tmp_dir}/README.md.current" "${tmp_dir}/README.md.generated" | head -100 || true
      echo
      log_error "To fix: npx ${pkg_spec} --readme charts/${chart}/README.md --values charts/${chart}/values.yaml"
      exit 1
    fi
    log_ok "README is up-to-date"
  else
    die "readme-generator not available. Install: npm install -g ${pkg_name}"
  fi
else
  log_warn "Skipping README validation (no documentation annotations found)"
  log_warn "To add documentation:"
  log_warn "  - For helm-docs: Add '# --' comments above values in values.yaml"
  log_warn "  - For readme-generator: Add '## @param' comments in values.yaml"
fi
