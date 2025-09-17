#!/usr/bin/env bash
# bash-prompt.sh — Lightweight git-aware prompt for devcontainer

__owf_git_branch() {
  local b
  b=$(git symbolic-ref --short -q HEAD 2> /dev/null || git rev-parse --short HEAD 2> /dev/null || true)
  [[ -n "${b}" ]] && printf "%s" "${b}"
}

__owf_prompt() {
  local exit=$?
  local cyan='\[\e[36m\]'
  local green='\[\e[32m\]'
  local red='\[\e[31m\]'
  local yellow='\[\e[33m\]'
  local reset='\[\e[0m\]'
  local branch
  branch=$(__owf_git_branch)
  local status color
  if [[ ${exit} -eq 0 ]]; then
    color=${green}
    status="✔"
  else
    color=${red}
    status="✘"
  fi
  if [[ -n "${branch}" ]]; then
    PS1="${color}${status}${reset} ${cyan}\u@\h${reset}:${yellow}\w${reset} (${branch})\n$ "
  else
    PS1="${color}${status}${reset} ${cyan}\u@\h${reset}:${yellow}\w${reset}\n$ "
  fi
}

PROMPT_COMMAND=__owf_prompt
