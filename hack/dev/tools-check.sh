#!/usr/bin/env bash
# tools-check.sh - Verify local tool versions match pins in hack/versions.env
# Intent: human-readable alternative to long Makefile one-liners.
# Exit non‑zero if any drift or missing tool is detected.

set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINS_FILE="${ROOT_DIR}/versions.env"

if [[ ! -f "${PINS_FILE}" ]]; then
  echo "[error] versions file missing: ${PINS_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${PINS_FILE}"

declare -i FAIL=0

print_header() { echo "== Tool Version Check =="; }

ver_norm() { printf '%s' "$1" | sed -E 's/^v//; s/[^0-9.].*$//'; }

ver_ge() { # return 0 if $1 >= $2
  local a b IFS=.
  # shellcheck disable=SC2312
  read -r -a a <<< "$(ver_norm "$1")"
  # shellcheck disable=SC2312
  read -r -a b <<< "$(ver_norm "$2")"
  for i in 0 1 2; do
    local ai=${a[${i}]:-0} bi=${b[${i}]:-0}
    if ((ai > bi)); then return 0; fi
    if ((ai < bi)); then return 1; fi
  done
  return 0
}

check() {
  local have="${1}" want="${2}" name="${3}"
  if [[ -z "${have}" ]]; then
    printf '[MISSING] %s\n' "${name}"
    FAIL+=1
    return
  fi
  if [[ "${have}" != "${want}" ]]; then
    printf '[DRIFT]   %s %s (expected %s)\n' "${name}" "${have}" "${want}"
    FAIL+=1
    return
  fi
  printf '[OK]      %s %s\n' "${name}" "${have}"
}

check_min() { # have, min, name
  local have="$1" min="$2" name="$3"
  if [[ -z "${have}" ]]; then
    printf '[MISSING] %s\n' "${name}"
    FAIL+=1
    return
  fi
  # shellcheck disable=SC2310
  if ver_ge "${have}" "${min}"; then
    printf '[OK]      %s %s (>= %s)\n' "${name}" "${have}" "${min}"
  else
    printf '[DRIFT]   %s %s (>= %s required)\n' "${name}" "${have}" "${min}"
    FAIL+=1
  fi
}

trim_v() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^v//'; }

# Collect versions (guard each command)
# shellcheck disable=SC2310
helm_ver=$(helm version --short 2> /dev/null | cut -d'+' -f1 | trim_v || true)

if command -v ct > /dev/null 2>&1; then
  ct_raw=$(ct version 2> /dev/null || true)
  # Support both formats: "Version: vX.Y.Z" and "ct version X.Y.Z"
  ct_ver=$(printf '%s\n' "${ct_raw}" | awk -F': ' '/^Version:/ {print $2}' | trim_v | head -n1)
  if [[ -z "${ct_ver}" ]]; then
    ct_ver=$(printf '%s\n' "${ct_raw}" | grep -Eo '[0-9]+(\.[0-9]+){1,3}' | head -n1 | trim_v)
  fi
else
  ct_ver=""
fi

# chart-releaser prints multiple lines; extract GitVersion line only
if command -v cr > /dev/null 2>&1; then
  cr_ver=$(cr version 2> /dev/null | awk -F': ' '/^GitVersion/ {print $2}' | trim_v | head -n1)
else
  cr_ver=""
fi

# shellcheck disable=SC2310
kubectl_ver=$(kubectl version --client --output=json 2> /dev/null | jq -r '.clientVersion.gitVersion' 2> /dev/null | trim_v || true)
# shellcheck disable=SC2310
kind_ver=$(kind version 2> /dev/null | awk '{print $2}' | trim_v || true)
# shellcheck disable=SC2310
yq_ver=$(yq --version 2> /dev/null | awk '{print $4}' | trim_v || true)
# shellcheck disable=SC2310
jq_ver=$(jq --version 2> /dev/null | sed 's/^jq-//' | trim_v || true)
# shellcheck disable=SC2310
yamllint_ver=$(yamllint --version 2> /dev/null | awk '{print $2}' | trim_v || true)
# shellcheck disable=SC2310
git_ver=$(git --version 2> /dev/null | awk '{print $3}' | trim_v || true)
# shellcheck disable=SC2310
cc_ver=$(conventional-changelog --version 2> /dev/null | trim_v || true)
# shellcheck disable=SC2310
readme_gen_ver=$(readme-generator --version 2> /dev/null | grep -Eo '[0-9]+(\.[0-9]+){1,3}' | head -n1 | trim_v || true)
# shellcheck disable=SC2310
node_ver=$(node --version 2> /dev/null | trim_v || true)
# shellcheck disable=SC2310
shellcheck_ver=$(shellcheck --version 2> /dev/null | awk '/version:/ {print $2}' | trim_v || true)
# shellcheck disable=SC2310
shfmt_ver=$(shfmt --version 2> /dev/null | trim_v || true)
# helm-docs outputs line like: "helm-docs version v1.14.2" — extract numeric version
# shellcheck disable=SC2310
helm_docs_ver=$(helm-docs --version 2> /dev/null | grep -Eo '[0-9]+(\.[0-9]+){1,3}' | head -n1 | trim_v || true)
# shellcheck disable=SC2310
act_ver=$(act --version 2> /dev/null | awk '{print $3}' | trim_v || true)
# shellcheck disable=SC2310
actionlint_ver=$(actionlint --version 2> /dev/null | awk '{print $2}' | trim_v || true)

print_header
check "${helm_ver}" "${HELM_VERSION:-}" HELM
check "${ct_ver}" "${CHART_TESTING_VERSION:-}" CT
check "${cr_ver}" "${CHART_RELEASER_VERSION:-}" CHART_RELEASER
check "${kubectl_ver}" "${KUBECTL_VERSION:-}" KUBECTL
check "${kind_ver}" "${KIND_VERSION:-}" KIND
check "${yq_ver}" "${YQ_VERSION:-}" YQ
check "${jq_ver}" "${JQ_VERSION:-}" JQ
check "${yamllint_ver}" "${YAMLLINT_VERSION:-}" YAMLLINT
check "${node_ver}" "${NODE_VERSION:-}" NODE
if command -v shellcheck > /dev/null 2>&1; then
  check "${shellcheck_ver}" "${SHELLCHECK_VERSION:-}" SHELLCHECK
fi
if command -v shfmt > /dev/null 2>&1; then
  check "${shfmt_ver}" "${SHFMT_VERSION:-}" SHFMT
fi
if command -v helm-docs > /dev/null 2>&1; then
  check "${helm_docs_ver}" "${HELM_DOCS_VERSION:-}" HELM_DOCS
fi
if command -v act > /dev/null 2>&1; then
  check "${act_ver}" "${ACT_VERSION:-}" ACT
fi
if command -v actionlint > /dev/null 2>&1; then
  check "${actionlint_ver}" "${ACTIONLINT_VERSION:-}" ACTIONLINT
fi

# Node-based generators (if globally installed)
if command -v conventional-changelog > /dev/null 2>&1; then
  check "${cc_ver}" "${CONVENTIONAL_CHANGELOG_CLI_VERSION:-}" CONVENTIONAL_CHANGELOG
fi
if command -v readme-generator > /dev/null 2>&1; then
  check "${readme_gen_ver}" "${BITNAMI_README_GENERATOR_VERSION:-}" README_GENERATOR
fi

# Git minimum version check
check_min "${git_ver}" "${GIT_MIN_VERSION:-2.40.0}" GIT

if ((FAIL > 0)); then
  echo
  echo "Version drift detected. Update hack/versions.env or install matching versions." >&2
  exit 1
fi

echo
echo "All pinned tool versions match."
