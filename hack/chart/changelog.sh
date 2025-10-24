#!/usr/bin/env bash
# changelog.sh - Update a chart's CHANGELOG.md using conventional-changelog scoped to chart path.
# Usage: changelog.sh <chart>

set -Eeuo pipefail
# Resolve repo root relative to this script to avoid dependence on caller CWD
script_dir=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../lib/log.sh
# shellcheck disable=SC1091
source "${script_dir}/../lib/log.sh"
chart="${1:-}"
[[ -z "${chart}" ]] && die "Usage: $0 <chart>"
# Resolve repo root relative to this script to avoid dependence on caller CWD
repo_root=$(cd "${script_dir}/../.." && pwd)
chart_dir="${repo_root}/charts/${chart}"
changelog="${chart_dir}/CHANGELOG.md"
[[ ! -d "${chart_dir}" ]] && die "chart dir missing: ${chart_dir}"

# Ensure file exists but do NOT truncate existing history; conventional-changelog will edit in-place.
if [[ ! -f "${changelog}" ]]; then
  touch "${changelog}"
fi

tag_prefix="${chart}-"
# Generate (retain existing sections; -r 1 to only generate latest). If duplicates appear, expand logic later.
CONVENTIONAL_CHANGELOG_CLI_VERSION="${CONVENTIONAL_CHANGELOG_CLI_VERSION:-}"
cc_pkg="conventional-changelog-cli"
if [[ -n "${CONVENTIONAL_CHANGELOG_CLI_VERSION}" ]]; then cc_spec="${cc_pkg}@${CONVENTIONAL_CHANGELOG_CLI_VERSION}"; else cc_spec="${cc_pkg}"; fi
if ! npx --yes "${cc_spec}" -p conventionalcommits --tag-prefix "${tag_prefix}" --commit-path "${chart_dir}" -i "${changelog}" -s -r 1; then
  log_warn "conventional-changelog exited non-zero; leaving existing changelog untouched"
fi

# If top line is an empty compare heading (no version text between brackets), annotate or remove it.
first_line=$(head -n1 "${changelog}" || true)
if [[ "${first_line}" =~ ^##\ \[]\(https://.+\.\.\. ]]; then
  # Are there any non-heading, non-blank lines after it?
  lines_after=$(tail -n +2 "${changelog}" | grep -v '^#' | grep -v '^\s*$' || true)
  if [[ -z "${lines_after}" ]]; then
    last_tag=$(git -C "${repo_root}" describe --tags --match "${chart}-*" --abbrev=0 2> /dev/null || echo "${chart}-0.0.0")
    sed -i "1s|.*|## No unreleased changes since ${last_tag}|" "${changelog}"
  fi
fi
