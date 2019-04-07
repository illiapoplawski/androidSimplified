#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides different logging level functions
#/
#/  Public Functions:
#/
#/ Usage: log <argument> [message]...
#/
#/ OPTIONS
#/    -h, --help
#/                Print this help message
#/    -d, --debug
#/                Print debug message
#/    -i, --info
#/                Print info message
#/    -w, --warn
#/                Print warn message
#/    -e, --error
#/                Print error message
#/
#/ EXAMPLES
#/    log -d "Debug statement"
#/    log --info "Info statement"
#/    log -w "Warn statement"
#/    log --error "Error statement"
#/

# Ensures script is only sourced once
if [[ ${LOGGING_GUARD:-} -eq 1 ]]; then
  return
else
  readonly LOGGING_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v LOGGING_SCRIPT_NAME ]]  || readonly LOGGING_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v LOGGING_SCRIPT_DIR ]]  || readonly LOGGING_SCRIPT_DIR="$( cd "$( dirname "$LOGGING_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

# Color definitions
source "$(dirname "$LOGGING_SCRIPT_DIR")"/defines/colour-defs.sh

# Usage: _debug [ARG]...
#
# Prints all arguments on the standard output stream,
# if debug output is enabled
_debug() {
  printf "${cyan:?}DEBUG - %s${reset:?}\n" "${*}" 1>&2
}

# Usage: _info [ARG]...
#
# Prints all arguments on the standard output stream
_info() {
  printf "${white:?}INFO - %s${reset:?}\n" "${*}" 1>&2
}

# Usage: _warn [ARG]...
#
# Prints all arguments on the standard error stream
_warn() {
  printf "${yellow:?}WARN - %s${reset:?}\n" "${*}" 1>&2
}

# Usage: _error [ARG]...
#
# Prints all arguments on the standard error stream
_error() {
  printf "${red:?}ERROR - %s${reset:?}\n" "${*}" 1>&2
}

# Show usage
_logUsage() {
  grep '^#/' "${LOGGING_SCRIPT_DIR}/${LOGGING_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Check if command line arguments are valid
_check_args() {
  if [ "${#}" -lt "1" ]; then
    _error "Expected log type argument"
    _logUsage
    exit 128
  fi
}

# Usage: log <log_type> [message]...
#
# Prints message for log type
log() {
  _check_args "$@"

  action="$1" && shift
  case "$action" in 
        -h|--help) _logUsage ;;
        -d|--debug) _debug "$@" ;;
        -i|--info) _info "$@"  ;;
        -w|--warn) _warn "$@" ;;
        -e|--error) _error "$@" ;;
        *) _error "Invalid log type"; _logUsage; exit 128 ;;
  esac
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./logging.sh\" instead."
  exit 1
fi