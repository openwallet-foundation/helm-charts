#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/log.sh
source "${script_dir}/../lib/log.sh"

# update_chart_version.sh <chart_dir> <new_version>
chart_dir="${1:-}"
new_version="${2:-}"

if [[ -z "${chart_dir}" || -z "${new_version}" ]]; then
  die "Usage: $0 <chart_dir> <new_version>"
fi

if [[ ! -f "${chart_dir}/Chart.yaml" ]]; then
  die "Chart.yaml not found in ${chart_dir}"
fi

tmp=$(mktemp)
awk -v ver="${new_version}" 'BEGIN{done=0} /^version:/ && !done { print "version: " ver; done=1; next } { print } END{ if(!done) print "version: " ver }' "${chart_dir}/Chart.yaml" > "${tmp}"
mv "${tmp}" "${chart_dir}/Chart.yaml"
