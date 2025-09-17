#!/usr/bin/env bash
# local-test.sh — Run a local CI-like test for a single chart
# Steps: helm dependency build → helm lint → ct lint → helm template → kind+ct install
# Usage: hack/chart/local-test.sh <chart-name>

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CHART_NAME="${1:-}"
if [[ -z "${CHART_NAME}" ]]; then
  echo "usage: $0 <chart-name>" >&2
  exit 2
fi

CHART_DIR="${ROOT_DIR}/charts/${CHART_NAME}"
if [[ ! -d "${CHART_DIR}" ]]; then
  echo "[error] chart directory not found: ${CHART_DIR}" >&2
  exit 3
fi

echo "[info] Building chart dependencies for ${CHART_NAME}"
(
  cd "${ROOT_DIR}/charts"
  # Add repos from Chart.yaml dependencies deterministically
  # shellcheck disable=SC2312
  mapfile -t repos < <(yq '.dependencies // [] | .[] | .repository' "${CHART_NAME}/Chart.yaml" | sed '/^null$/d' | sort -u)
  for repo in "${repos[@]:-}"; do
    name="$(sed -E 's|https?://||;s|/|_|g;s|[^a-zA-Z0-9_-]||g' <<< "${repo}")"
    echo "  - helm repo add ${name} ${repo}"
    helm repo add "${name}" "${repo}" > /dev/null 2>&1 || true
  done
  helm repo update > /dev/null 2>&1 || true
  helm dependency build "${CHART_NAME}"
)

echo "[info] Helm lint"
helm lint "${CHART_DIR}"

if [[ -f "${ROOT_DIR}/.github/ct.yaml" ]]; then
  echo "[info] ct lint"
  ct lint --charts "${CHART_DIR}" --config "${ROOT_DIR}/.github/ct.yaml"
else
  echo "[warn] skipping ct lint (no .github/ct.yaml)"
fi

echo "[info] helm template (smoke)"
helm template "${CHART_DIR}" > /dev/null

echo "[info] ct install in ephemeral kind cluster"
"${SCRIPT_DIR}/ct-install.sh" "${CHART_NAME}"

echo "[info] local CI-like test completed successfully for ${CHART_NAME}"
