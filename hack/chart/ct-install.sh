#!/usr/bin/env bash
# ct-install.sh - Run a chart-testing install test for a given chart in an ephemeral kind cluster.
# Usage: ct-install.sh <chart>

set -Eeuo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
chart="${1:-}"
if [[ -z "${chart}" ]]; then
  echo "Usage: $0 <chart-name>" >&2
  exit 2
fi
chart_dir="charts/${chart}"
if [[ ! -d "${chart_dir}" ]]; then
  echo "[error] Chart directory not found: ${chart_dir}" >&2
  exit 1
fi
if [[ ! -f .github/ct.yaml ]]; then
  echo "[error] Missing .github/ct.yaml config" >&2
  exit 1
fi
cluster="owf-${chart}-dev"
kc_dir="${repo_root}/.kube"
kc_file="${kc_dir}/${cluster}.kubeconfig"
mkdir -p "${kc_dir}"
export KUBECONFIG="${kc_file}"
echo "[info] Creating kind cluster ${cluster}"
if ! kind create cluster --name "${cluster}" --wait 60s; then
  echo "[error] Failed to create cluster" >&2
  exit 1
fi
kind export kubeconfig --name "${cluster}" > /dev/null 2>&1 || true
trap 'echo "[info] Deleting cluster ${cluster}"; kind delete cluster --name "${cluster}" >/dev/null 2>&1 || true' EXIT

set +e
ct install --charts "${chart_dir}" --config .github/ct.yaml
rc=$?
set -e
if [[ ${rc} -ne 0 ]]; then
  echo "[error] Install test failed" >&2
  exit "${rc}"
fi
echo "[info] Install test succeeded for ${chart}"
