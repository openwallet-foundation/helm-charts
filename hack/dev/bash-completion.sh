#!/usr/bin/env bash
# bash-completion.sh — Tab completion for chart-* helpers and chart names

_owf_chart_names() {
  # Use find to list only immediate subdirectories under charts/
  find charts -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2> /dev/null
}

_complete_chart_cmd() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  case "${prev}" in
    chart-release-pr | chart-docs | chart-changelog | chart-ct-install)
      # shellcheck disable=SC2312
      mapfile -t COMPREPLY < <(compgen -W "$(_owf_chart_names)" -- "${cur}")
      return 0
      ;;
    --base)
      # shellcheck disable=SC2312
      mapfile -t COMPREPLY < <(compgen -W "main" -- "${cur}")
      return 0
      ;;
    *) ;;
  esac
  # First arg
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    # shellcheck disable=SC2312
    mapfile -t COMPREPLY < <(compgen -W "$(_owf_chart_names)" -- "${cur}")
  fi
}

complete -F _complete_chart_cmd chart-release-pr
complete -F _complete_chart_cmd chart-docs
complete -F _complete_chart_cmd chart-changelog
complete -F _complete_chart_cmd chart-ct-install
complete -F _complete_chart_cmd chart-local-test
