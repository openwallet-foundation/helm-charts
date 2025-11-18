#!/usr/bin/env bash
# ct-install.sh - Run a chart-testing install test for a given chart in an ephemeral kind cluster.
# Usage: ct-install.sh <chart>

set -Eeuo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)

# shellcheck source=../lib/log.sh
source "${repo_root}/hack/lib/log.sh"

chart="${1:-}"
if [[ -z "${chart}" ]]; then
  die "Usage: $0 <chart-name>"
fi
chart_dir="charts/${chart}"
if [[ ! -d "${chart_dir}" ]]; then
  die "Chart directory not found: ${chart_dir}"
fi
if [[ ! -f .github/ct.yaml ]]; then
  die "Missing .github/ct.yaml config"
fi
cluster="owf-${chart}-dev"
kc_dir="${repo_root}/.kube"
kc_file="${kc_dir}/${cluster}.kubeconfig"
mkdir -p "${kc_dir}"
export KUBECONFIG="${kc_file}"
log_info "Creating kind cluster ${cluster}"
if ! kind create cluster --name "${cluster}" --wait 60s; then
  die "Failed to create cluster"
fi
kind export kubeconfig --name "${cluster}" > /dev/null 2>&1 || true
trap 'log_info "Deleting cluster ${cluster}"; kind delete cluster --name "${cluster}" >/dev/null 2>&1 || true' EXIT

set +e
ct install --charts "${chart_dir}" --config .github/ct.yaml
rc=$?
set -e
if [[ ${rc} -ne 0 ]]; then
  die "Install test failed"
fi
log_ok "Install test succeeded for ${chart}"
