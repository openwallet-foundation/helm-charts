#!/usr/bin/env bash
set -Eeuo pipefail

# uninstall-cli.sh — Remove installed CLI shims

removed=0
remove_from() { # dir
  local dir="$1"
  for name in chart-release-pr chart-docs chart-changelog chart-ct-install \
    owf-release-pr owf-docs owf-changelog owf-ct-install; do
    if [[ -f "${dir}/${name}" ]]; then
      rm -f "${dir}/${name}"
      echo "[info] Removed ${dir}/${name}"
      removed=$((removed + 1))
    fi
  done
}

for dir in "/usr/local/bin" "${HOME}/.local/bin" "/workspace/.bin"; do
  if [[ -d "${dir}" ]]; then
    remove_from "${dir}"
  fi
done

if [[ ${removed} -eq 0 ]]; then
  echo "[info] No CLI shims found"
else
  echo "[info] Uninstall complete (${removed} removed)"
fi
