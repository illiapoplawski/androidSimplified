#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides common functions for math
#/
#/  Public Functions:
#/
#/ Usage: mathFunctions [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   isInt <arg>
#/                Test if input is an int
#/   isNumber <arg>
#/                Test if input is a number
#/
#/ EXAMPLES
#/   mathFunctions isInt <arg>
#/   mathFunctions isNumber <arg>
#/   mathFunctions -h 
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _isInteger <value>
#
# Checks if input is a valid integer
_isInteger() {
  local re='^[0-9]+$'
  if [[ ! $number =~ $re ]]; then
    exit 1; #not a number
  else
    exit 0; #valid number
  fi
}

# Usage: _isNumber <value>
#
# Checks if input is a valid number
_isNumber() {
  local re='^[0-9]+([.][0-9]+)?$'
  if [[ ! $number =~ $re ]]; then
    exit 1; #not a number
  else
    exit 0; #valid number
  fi
}

# Show math functions usage info
_mathFunctionsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: mathFunctions [arg]
#
# Common functions for numbers
mathFunctions(){
  local number

  local action
  action="$1"
  shift
  case "$action" in
    -h|--help) 
      _mathFunctionsUsage
      exit 0
      ;;
    isInt)
      number="$1"
      _isInteger
      ;;
    isNumber)
      number="$1"
      _isNumber
      ;;
    *) log -e "Unknown arguments passed"; _mathFunctionsUsage; exit 128 ;;
  esac
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./mathFunctions.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && mathFunctions "$@"
