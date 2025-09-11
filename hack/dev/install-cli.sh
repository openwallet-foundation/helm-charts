#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# install-cli.sh — Install CLI shims to run repo scripts from anywhere
# Chooses an install dir in this order:
#   1) /usr/local/bin (if writable)
#   2) ~/.local/bin (creates if needed)
#   3) /workspace/.bin (repo-local fallback)
#
# Commands installed (no "owf-" prefix):
#   - chart-release-pr  -> hack/chart/release-pr.sh
#   - chart-docs        -> hack/chart/docs.sh
#   - chart-changelog   -> hack/chart/changelog.sh
#   - chart-ct-install  -> hack/chart/ct-install.sh
#
# The wrappers resolve the repo path via $OWF_HELM_REPO, or fall back to /workspace
# (devcontainer default). If neither works, they instruct the user to export
# OWF_HELM_REPO=/absolute/path/to/owf-helm-charts.

# Pick destination directory
if [[ -w "/usr/local/bin" ]]; then
  DEST_DIR="/usr/local/bin"
elif [[ -d "${HOME}/.local/bin" || ! -e "${HOME}/.local/bin" ]]; then
  DEST_DIR="${HOME}/.local/bin"
  mkdir -p "${DEST_DIR}"
else
  DEST_DIR="/workspace/.bin"
  mkdir -p "${DEST_DIR}"
fi

write_wrapper() { # name, relpath
  local name="$1"
  local rel="$2"
  local target="${DEST_DIR}/${name}"
  cat > "${target}" << 'WRAP'
#!/usr/bin/env bash
set -Eeuo pipefail
repo="${OWF_HELM_REPO:-}"
embed_repo="__EMBED_REPO__"
rel="__REL__"

# Resolve repo path at runtime: env override > embedded path > devcontainer default
if [[ -n "${repo}" && -d "${repo}/.git" ]]; then
  :
elif [[ -d "${embed_repo}/.git" ]]; then
  repo="${embed_repo}"
elif [[ -d "/workspace/.git" ]]; then
  repo="/workspace"
else
  echo "[error] Could not locate owf-helm-charts repo. Set OWF_HELM_REPO=/absolute/path" >&2
  exit 1
fi

exec "${repo}/${rel}" "$@"
WRAP
  # Replace placeholders with actual paths without introducing quoting issues
  sed -i "s|__EMBED_REPO__|${repo_root}|g; s|__REL__|${rel}|g" "${target}"
  chmod +x "${target}"
  echo "[info] Installed ${target}"
}

# Determine repo root for embedding absolute path
repo_root=$(git rev-parse --show-toplevel 2> /dev/null || true)
if [[ -z "${repo_root}" ]]; then
  # Fallback: assume script is inside repo under hack/dev/
  script_dir=$(cd "$(dirname "$0")" && pwd)
  repo_root=$(cd "${script_dir}/../.." && pwd)
fi

write_wrapper "chart-release-pr" "hack/chart/release-pr.sh"
write_wrapper "chart-docs" "hack/chart/docs.sh"
write_wrapper "chart-changelog" "hack/chart/changelog.sh"
write_wrapper "chart-ct-install" "hack/chart/ct-install.sh"
write_wrapper "chart-local-test" "hack/chart/local-test.sh"

case ":${PATH}:" in
  *:"${DEST_DIR}":*) echo "[info] Installed to ${DEST_DIR} (on PATH)" ;;
  *) echo "[warn] ${DEST_DIR} is not on PATH. To use now: export PATH=\"${DEST_DIR}:${PATH}\"" ;;
esac
