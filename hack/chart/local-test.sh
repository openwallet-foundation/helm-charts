#!/usr/bin/env bash
# local-test.sh — Run a local CI-like test for a single chart
# Steps: helm dependency build → helm lint → ct lint → helm template → kind+ct install
# Usage: hack/chart/local-test.sh <chart-name>

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../lib/log.sh
source "${SCRIPT_DIR}/../lib/log.sh"

CHART_NAME="${1:-}"
if [[ -z "${CHART_NAME}" ]]; then
  die "usage: $0 <chart-name>"
fi

CHART_DIR="${ROOT_DIR}/charts/${CHART_NAME}"
if [[ ! -d "${CHART_DIR}" ]]; then
  die "chart directory not found: ${CHART_DIR}"
fi

log_info "Building chart dependencies for ${CHART_NAME}"
(
  cd "${ROOT_DIR}/charts"
  # Add repos from Chart.yaml dependencies deterministically
  repo_list=$(yq '.dependencies // [] | .[] | .repository' "${CHART_NAME}/Chart.yaml" | sed '/^null$/d' | sort -u)
  mapfile -t repos <<< "${repo_list}"
  for repo in "${repos[@]:-}"; do
    name="$(sed -E 's|https?://||;s|/|_|g;s|[^a-zA-Z0-9_-]||g' <<< "${repo}")"
    echo "  - helm repo add ${name} ${repo}"
    helm repo add "${name}" "${repo}" > /dev/null 2>&1 || true
  done
  helm repo update > /dev/null 2>&1 || true
  helm dependency build "${CHART_NAME}"
)

if [[ -f "${ROOT_DIR}/.github/ct.yaml" ]]; then
  log_info "ct lint (helm lint + yamllint + maintainers + version)"
  ct lint --charts "${CHART_DIR}" --config "${ROOT_DIR}/.github/ct.yaml"
else
  log_warn "skipping ct lint (no .github/ct.yaml)"
fi

log_info "helm template (smoke)"
helm template "${CHART_DIR}" > /dev/null

log_info "ct install in ephemeral kind cluster"
"${SCRIPT_DIR}/ct-install.sh" "${CHART_NAME}"

log_ok "local test completed successfully for ${CHART_NAME}"
