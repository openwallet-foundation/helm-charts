#!/usr/bin/env bash
# log.sh — Shared logging helpers for scripts
# Usage: source this file, then call log_info/log_warn/log_error/die

if [[ -n "${_OWF_LOG_LIB_SOURCED:-}" ]]; then
  return 0
fi
_OWF_LOG_LIB_SOURCED=1

# Colors (disable with NO_COLOR=1)
if [[ "${NO_COLOR:-0}" != "1" ]]; then
  _c_reset='\033[0m'
  _c_red='\033[31m'
  _c_green='\033[32m'
  _c_yellow='\033[33m'
  _c_cyan='\033[36m'
else
  _c_reset=''
  _c_red=''
  _c_green=''
  _c_yellow=''
  _c_cyan=''
fi

_fmt() { # level msg
  local lvl="$1"
  shift
  local prefix
  case "${lvl}" in
    INFO) prefix="${_c_cyan}ℹ${_c_reset}" ;;
    OK) prefix="${_c_green}✔${_c_reset}" ;;
    WARN) prefix="${_c_yellow}⚠${_c_reset}" ;;
    ERR) prefix="${_c_red}✘${_c_reset}" ;;
    *) prefix="${_c_cyan}>${_c_reset}" ;;
  esac
  printf '%b %s\n' "${prefix}" "$*"
}

log_info() { _fmt INFO "$@"; }
log_ok() { _fmt OK "$@"; }
log_warn() { _fmt WARN "$@"; }
log_error() { _fmt ERR "$@"; }
die() {
  log_error "$@"
  exit 1
}
