#!/usr/bin/env bash
set -euo pipefail

# prepare_release_branch.sh <chart_name> <new_version>
chart="${1:-}"
new_version="${2:-}"
branch="release/${chart}-v${new_version}"
echo "${branch}"
