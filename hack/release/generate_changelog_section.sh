#!/usr/bin/env bash
set -euo pipefail

# generate_changelog_section.sh <chart_dir> <new_version> <types_json>
chart_dir="${1:-}"
new_version="${2:-}"
types_json="${3:-}"
date_str=$(date +%Y-%m-%d)
changelog_file="${chart_dir}/CHANGELOG.md"
tmp_section=$(mktemp)

echo "## ${new_version} (${date_str})" > "${tmp_section}"
order=(feat fix perf refactor chore docs other)
titles=("Features" "Fixes" "Performance" "Refactors" "Chore" "Documentation" "Other Changes")

idx=0
for key in "${order[@]}"; do
  # extract array items for key from JSON (simple parser; expects no nested quotes)
  raw=$(echo "${types_json}" | sed -n "s/.*\"${key}\":\[\([^]]*\)\].*/\1/p") || true
  [[ -z "${raw}" ]] && idx=$((idx + 1)) && continue
  IFS=',' read -r -a items <<< "${raw}"
  if [[ ${#items[@]} -gt 0 ]]; then
    echo "" >> "${tmp_section}"
    echo "### ${titles[${idx}]}" >> "${tmp_section}"
    for it in "${items[@]}"; do
      clean=$(echo "${it}" | sed 's/^\"//;s/\"$//;s/\\"/"/g')
      echo "${clean}" >> "${tmp_section}"
    done
  fi
  idx=$((idx + 1))
done

# Prepend to existing CHANGELOG (ensure file exists)
touch "${changelog_file}"
tmp_all=$(mktemp)
cat "${tmp_section}" "${changelog_file}" > "${tmp_all}"
mv "${tmp_all}" "${changelog_file}"

echo "Generated changelog section for ${new_version}" >&2
