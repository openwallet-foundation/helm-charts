#!/usr/bin/env bash
set -euo pipefail

# update_chart_version.sh <chart_dir> <new_version>
chart_dir="${1:-}"
new_version="${2:-}"
tmp=$(mktemp)
awk -v ver="${new_version}" 'BEGIN{done=0} /^version:/ && !done { print "version: " ver; done=1; next } { print } END{ if(!done) print "version: " ver }' "${chart_dir}/Chart.yaml" > "${tmp}"
mv "${tmp}" "${chart_dir}/Chart.yaml"
