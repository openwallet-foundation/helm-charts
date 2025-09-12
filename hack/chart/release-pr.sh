#!/usr/bin/env bash
# release-pr.sh — Developer convenience script to open a Release PR for a chart.
#
# Mirrors the CI Release‑PR flow:
#   1) Detect last released tag for the chart (<chart>-<semver>)
#   2) Classify commits scoped to charts/<chart> and decide bump level
#   3) Compute next version and update Chart.yaml only
#   4) Regenerate README and CHANGELOG deterministically
#   5) Create a release/<chart>-v<version> branch, commit, and open a PR (if gh is installed)
#
# Notes:
# - Local helper only. CI composes hack/release/* + hack/chart/* scripts directly.
# - Generated files: charts/<chart>/README.md and CHANGELOG.md — don’t hand-edit for releases.
# - Requires: git, yq, Node (npx), and repo scripts available in this repo.
#
# Usage:
#   hack/chart/release-pr.sh <chart> [--base <branch>] [--no-pr]
#
# Examples:
#   hack/chart/release-pr.sh acapy
#   hack/chart/release-pr.sh acapy --base main --no-pr

set -Eeuo pipefail

base_branch="main"
open_pr=true

chart="${1:-}"
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_branch="${2:-main}"
      shift 2
      ;;
    --no-pr)
      open_pr=false
      shift
      ;;
    -h | --help)
      sed -n '1,60p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "[error] Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${chart}" ]]; then
  echo "Usage: hack/chart/release-pr.sh <chart> [--base <branch>] [--no-pr]" >&2
  exit 2
fi

# Ensure we run from repo root
repo_root=$(git rev-parse --show-toplevel)
cd "${repo_root}"

chart_dir="charts/${chart}"
if [[ ! -d "${chart_dir}" ]]; then
  echo "[error] chart dir missing: ${chart_dir}" >&2
  exit 1
fi

current_version=$(yq '.version' "${chart_dir}/Chart.yaml")
last_tag=$(git describe --tags --match "${chart}-*" --abbrev=0 2> /dev/null || echo "")
printf '[info] Last released tag: %s\n' "${last_tag:-<none>}"

# 1) Classify commits scoped to chart path
classify_out=$(hack/release/classify_commits.sh "${chart_dir}" "${last_tag}")
BUMP_LEVEL=$(printf '%s\n' "${classify_out}" | sed -n 's/^BUMP_LEVEL=//p')
HAS_COMMITS=$(printf '%s\n' "${classify_out}" | sed -n 's/^HAS_COMMITS=//p')

if [[ "${HAS_COMMITS}" != "true" || "${BUMP_LEVEL}" == "none" ]]; then
  printf '[info] No relevant commits for %s; nothing to release.\n' "${chart}"
  exit 0
fi

# 2) Compute next version (no manual override here; keep in sync with CI)
new_version=$(hack/release/next_version.sh "${current_version}" "" "${BUMP_LEVEL}")
printf '[info] Version bump (%s): %s -> %s\n' "${BUMP_LEVEL}" "${current_version}" "${new_version}"

# 3) Update Chart.yaml version deterministically
hack/release/update_chart_version.sh "${chart_dir}" "${new_version}"

# 4) Regenerate docs and changelog
hack/chart/docs.sh "${chart}"
hack/chart/changelog.sh "${chart}"

# 5) Create branch, commit, and optionally open a PR
branch="release/${chart}-v${new_version}"
if git rev-parse --verify "${branch}" > /dev/null 2>&1; then
  git switch "${branch}"
else
  git switch -c "${branch}"
fi

git add "${chart_dir}/Chart.yaml" "${chart_dir}/README.md" "${chart_dir}/CHANGELOG.md"
if git diff --cached --quiet; then
  echo "[info] No changes to commit (already up to date)"
else
  git commit -m "chore(release): ${chart} ${new_version}"
fi

if [[ "${open_pr}" == "true" ]]; then
  if command -v gh > /dev/null 2>&1; then
    pr_body="Automated release PR (local helper)

Bump level: ${BUMP_LEVEL}
Chart: ${chart}
Version: ${new_version}
"
    gh pr create \
      --title "chore(release): ${chart} ${new_version}" \
      --body "${pr_body}" \
      --base "${base_branch}" || echo "[info] PR create skipped"
  else
    echo "[info] Install GitHub CLI (gh) to auto-open PR, or pass --no-pr." >&2
  fi
else
  echo "[info] --no-pr set; not opening a PR. Branch: ${branch}"
fi

printf '[info] Branch %s ready.\n' "${branch}"
