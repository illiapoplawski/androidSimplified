#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides common functions for log files
#/
#/  Public Functions:
#/
#/ Usage: arrayFunctions [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   contains
#/                Searches an array
#/          -a, --array <var name>
#/                Array to search
#/          -v, --value <value>
#/                Value to search for in array
#/
#/ EXAMPLES
#/   arrayFunctions contains -a array -v <val>
#/   arrayFunctions -h
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _contains
#
# Checks if array contains a value
_contains () {
  for i in "${array_ref[@]}"; do
    if [[ "$i" == "$array_value" ]]; then
      exit 0
    fi
  done
  exit 1
}

# Show array functions usage info
_arrayFunctionsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: arrayFunctions [arg]
#
# Common functions for arrays
arrayFunctions(){
  local array_value
  local array_ref

  local action
  action="$1"
  shift
  case "$action" in
    -h|--help) 
      _arrayFunctionsUsage
      exit 0
      ;;
    contains)
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -a|--array)
            local arrs
            shift # past argument
            arrs=("$@")
            if [[ ${#arrs[@]} -gt 0 ]]; then
              array_ref=()
              for arr in "${arrs[@]}"; do
                if [[ "$arr" != '-'* ]]; then
                  shift # past value
                  if [[ -n $arr && "$arr" != " " ]]; then
                    array_ref+=("$arr")
                  fi
                else
                  break
                fi
              done
            fi
            ;;
          -v|--value)
            local val="$2"
            shift # past argument
            if [[ "$val" != '-'* ]]; then
              shift # past value
              if [[ -n $val && "$val" != " " ]]; then
                array_value="$val"
              else
                log -w "Empty array value parameter"
              fi
            else
              log -w "No array value parameter specified"
            fi
            ;;
          *) 
            log -w "Unknown argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _contains
      ;;
    *) log -e "Unknown arguments passed"; _arrayFunctionsUsage; exit 128 ;;
  esac
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./arrayFunctions.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && arrayFunctions "$@"
