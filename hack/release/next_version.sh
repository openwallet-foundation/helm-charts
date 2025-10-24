#!/usr/bin/env bash
set -euo pipefail

# next_version.sh <current_version> <bump_override_or_empty> <auto_bump>
current="${1:-}"
override="${2:-}"
auto_bump="${3:-}"

major=$(echo "${current}" | cut -d. -f1)
minor=$(echo "${current}" | cut -d. -f2)
patch=$(echo "${current}" | cut -d. -f3 | sed 's/[^0-9].*//')

inc() { echo $(($1 + 1)); }

decide="${override:-${auto_bump}}"
case "${decide}" in
  major)
    major=$(inc "${major}")
    minor=0
    patch=0
    ;;
  minor)
    minor=$(inc "${minor}")
    patch=0
    ;;
  patch | none | '')
    patch=$(inc "${patch}")
    ;;
  *)
    echo "Unknown bump '${decide}'" >&2
    exit 1
    ;;
esac

echo "${major}.${minor}.${patch}"
