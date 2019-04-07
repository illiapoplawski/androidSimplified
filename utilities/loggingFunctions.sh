#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides common functions for log files
#/
#/  Public Functions:
#/
#/ Usage: loggingFunctions [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   clearLog
#/                Clears a log file
#/          -f, --file <path>
#/                Path of the log to clear
#/
#/ EXAMPLES
#/   loggingFunctions clearLog -f <path>
#/   loggingFunctions -h
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _clearLog
#
# Clears the upload log
_clearLog() {
  if [[ ! -v log_file || -z $log_file || "$log_file" == " " ]]; then
    log_file=$("$SCRIPT_DIR"/userFunctions.sh getFile -t "Select your log file" -o "$HOME") || {
      log -w "No log file selected"
      exit 1
    }
  fi

  if [[ -s $log_file ]]; then
    : > "$log_file"
  fi
}

# Show logging functions usage info
_loggingFunctionsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: loggingFunctions [arg]
#
# Common functions for log files
loggingFunctions(){
  local log_file

  local action
  action="$1"
  shift
  case "$action" in
    -h|--help) 
      _loggingFunctionsUsage
      exit 0
      ;;
    clearLog)
      while [[ $# -gt 0 ]]; do
        action="$1"
        case "$action" in
          -f|--file)
            local file="$2"
            shift # past argument
            if [[ -n "$file" && "$file" != " " && "$file" != '-'* ]]; then
              log_file="$file"
              shift # past value
            else
              log -w "No file parameter specified"
            fi
            ;;
          *) log -e "Unknown clearLog arguments passed"; _loggingFunctionsUsage; exit 128 ;;
        esac
      done
      _clearLog
      ;;
    *) log -e "Unknown arguments passed"; _loggingFunctionsUsage; exit 128 ;;
  esac
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./loggingFunctions.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && loggingFunctions "$@"
