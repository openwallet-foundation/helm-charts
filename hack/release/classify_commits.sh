#!/usr/bin/env bash
set -Eeuo pipefail

# classify_commits.sh
# Determines bump level (major|minor|patch|none) and lists commit messages by type
# Scoped to a chart path to avoid cross-chart noise.
# Usage: classify_commits.sh <chart_path> <from_ref>
# Outputs environment-style variables:
#   BUMP_LEVEL=major|minor|patch|none
#   HAS_COMMITS=true|false
#   TYPES_JSON=<json map of type -> array of messages>

chart_path="${1:-}"
from_ref="${2:-}"

log_range="${from_ref}..HEAD"
commits=$(git log --no-merges --pretty=format:'%H%x09%s%x09%b' -- "${chart_path}" || true)

if [[ -n "${from_ref}" ]] && git rev-parse -q --verify "${from_ref}" > /dev/null 2>&1; then
  commits=$(git log --no-merges --pretty=format:'%H%x09%s%x09%b' "${log_range}" -- "${chart_path}" || true)
fi

if [[ -z "${commits}" ]]; then
  echo "BUMP_LEVEL=none"
  echo "HAS_COMMITS=false"
  echo "TYPES_JSON={}"
  exit 0
fi

major=false
minor=false
patch=false

feat_msgs=()
fix_msgs=()
perf_msgs=()
refactor_msgs=()
chore_msgs=()
docs_msgs=()
other_msgs=()

while IFS=$'\t' read -r sha subject body; do
  type_scope=$(echo "${subject}" | sed -E 's/^(feat|fix|perf|refactor|chore|docs)(\([^)]*\))?!.*/\1!/' | sed -E 's/^(feat|fix|perf|refactor|chore|docs)(\([^)]*\))?:.*/\1/')
  breaking=false
  if echo "${subject}" | grep -q '!:'; then breaking=true; fi
  if echo "${body}" | grep -q 'BREAKING CHANGE:'; then breaking=true; fi
  msg="- ${subject} (${sha:0:7})"
  case "${type_scope}" in
    feat*)
      feat_msgs+=("${msg}")
      minor=true
      ;;
    fix*)
      fix_msgs+=("${msg}")
      patch=true
      ;;
    perf*)
      perf_msgs+=("${msg}")
      patch=true
      ;;
    refactor*)
      refactor_msgs+=("${msg}")
      patch=true
      ;;
    chore*)
      chore_msgs+=("${msg}")
      ;;
    docs*)
      docs_msgs+=("${msg}")
      ;;
    *)
      other_msgs+=("${msg}")
      patch=true
      ;;
  esac
  if ${breaking}; then major=true; fi
done <<< "${commits}"

if ${major}; then
  bump=major
elif ${minor}; then
  bump=minor
elif ${patch}; then
  bump="patch"
else
  bump=none
fi

# Build JSON (minimal, no external deps)
json='{'
first=true
emit_array() { # name, values...
  local name="${1}"
  shift || true
  local arr=("$@")
  [[ ${#arr[@]} -eq 0 ]] && return 0
  ${first} || json+=','
  first=false
  json+="\"${name}\":["
  local first_item=true
  for line in "${arr[@]}"; do
    line_escaped=$(printf '%s' "${line}" | sed 's/"/\\"/g')
    if ${first_item}; then
      json+="\"${line_escaped}\""
      first_item=false
    else
      json+=",\"${line_escaped}\""
    fi
  done
  json+="]"
}

emit_array feat "${feat_msgs[@]}"
emit_array fix "${fix_msgs[@]}"
emit_array perf "${perf_msgs[@]}"
emit_array refactor "${refactor_msgs[@]}"
emit_array chore "${chore_msgs[@]}"
emit_array docs "${docs_msgs[@]}"
emit_array other "${other_msgs[@]}"
json+='}'

echo "BUMP_LEVEL=${bump}"
echo "HAS_COMMITS=true"
echo "TYPES_JSON=${json}"
