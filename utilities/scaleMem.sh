#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Returns half of value entered rounded down to nearest integer
#/
#/  Public Functions:
#/
#/ Usage: $scaleMem <OPTIONS>
#/
#/  OPTIONS: 
#/     -h, --help
#/                Print this help message
#/     -s, --scale <scale>
#/                The scale to apply to the memory value provided
#/     -m, --memory <memory value>
#/                The memory value to scale
#/       
#/  EXAMPLES:
#/     scaleMem -m <mem val> -s <scale>
#/     scaleMem -h
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _scaleMem <memory value>
#
# Returns a scaled memory value from the one provided
_scaleMem() {
  local scaledMemRaw
  local scaledMemAdjusted
  local scaledMemRounded

  if [[ ! -v total_mem || -z $total_mem || "$total_mem" == " " ]]; then
    total_mem=$("$SCRIPT_DIR"/userFunctions.sh getInput -t "Scale Memory" -d "Enter your total memory") || exit $?
  fi
  
  "$SCRIPT_DIR"/mathFunctions.sh isNumber "$total_mem" || {
    log -e "Invalid memory value"
    _scaleMemUsage
    exit 128
  }

  if [[ ! -v mem_scale || -z $mem_scale || "$mem_scale" == " " ]]; then
    mem_scale=$("$SCRIPT_DIR"/userFunctions.sh getInput -t "Scale Memory" -d "Enter the memory scale" -i "0.75")
  fi
  
  "$SCRIPT_DIR"/mathFunctions.sh isNumber "$mem_scale" || {
    log -e "Invalid scale value.  Using default value"
    mem_scale=0.75
  }
  
  scaledMemRaw=$(bc -l <<< "scale = 1; $total_mem * $mem_scale")
  scaledMemAdjusted=$(echo "$scaledMemRaw + 0.5" | bc) # Add 0.5 to raw value to round it to nearest integer
  scaledMemRounded=${scaledMemAdjusted%.*}
  echo "$scaledMemRounded"
  exit 0
}

# Show scale mem usage
_scaleMemUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: scaleMem <arg>
#
# Returns a scaled memory value rounded to the nearest integer
scaleMem(){
  local total_mem
  local mem_scale

  local action
  if [[ ${#} -eq 0 ]]; then
    _scaleMem
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      if [[ "$action" != '-'* ]]; then
        shift
        continue
      fi
      case "$action" in
        -h|--help) 
          shift
          _scaleMemUsage
          return 0
         ;;
        -s|--scale) 
          local val="$2"
          shift # past argument
          if [[ "$val" != '-'* ]]; then
            shift # past value
            if [[ -n $val && "$val" != " " ]]; then
              mem_scale="$val"
            else 
              log -w "No scale parameter specified"
            fi
          else
            log -w "No memory scale parameter specified"
          fi
          ;;
        -m|--memory) 
          local value="$2"
          shift # past argument
          if [[ "$value" != '-'* ]]; then
            shift # past value
            if [[ -n $value && "$value" != " " ]]; then
              total_mem="$value"
            else
              log -w "Empty memory value provided"
            fi
          else
            log -w "No memory value specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _scaleMem
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./scaleMem.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && scaleMem "$@"
