#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up Ninja
#/
#/  Public Functions:
#/
#/ Usage: setupNinja [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -a|--auto
#/                Auto set ninja to recommended settings
#/   -n, --ninja <true|false>
#/                Automatically set ninja without dialog
#/
#/ EXAMPLES
#/   setupNinja
#/   setupNinja -n true
#/   setupNinja -h
#/   setupNinja -a
#/  

# Ensures script is only sourced once
if [[ ${SETUP_NINJA_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SETUP_NINJA_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SETUP_NINJA_SCRIPT_NAME ]]  || readonly SETUP_NINJA_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SETUP_NINJA_SCRIPT_DIR ]]  || readonly SETUP_NINJA_SCRIPT_DIR="$( cd "$( dirname "$SETUP_NINJA_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SETUP_NINJA_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupNinja
#
# Sets up Ninja
_setupNinja() {
  if [[ -v autoNinja ]]; then
    USE_NINJA=true
  else
    if [[ ! -v USE_NINJA || -z $USE_NINJA || "$USE_NINJA" == " " ]]; then
      if "$(dirname "$SETUP_NINJA_SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Setup Ninja" -d "Would you like to use NINJA to compile the source code?"; then
        USE_NINJA=true
      else
        USE_NINJA=false
      fi
    fi
  fi
  if [[ -v USE_NINJA ]]; then
    log -i "Compiling with NINJA"
  else
    log -i "Not compiling with NINJA"
  fi
  export USE_NINJA
}

# Show setup ninja usage info
_setupNinjaUsage() {
  grep '^#/' "${SETUP_NINJA_SCRIPT_DIR}/${SETUP_NINJA_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupNinja [arg]
#
# Sets up Ninja
setupNinja(){
  local autoNinja
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupNinja
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
          _setupNinjaUsage
          return 0
          ;;
        -a|--auto) 
          shift
          autoNinja=true
          ;;
        -n|--ninja) 
          local value="$2"
          shift # past argument
          if [[ "$value" != '-'* ]]; then
            shift # past value
            if [[ -n $value && "$value" != " " ]]; then
              if [[ "$value" = "true" || "$value" = "false" ]]; then
                USE_NINJA="$value"
              else
                log -e "Unknown arguments passed"; _setupNinjaUsage; return 128
              fi
            else
              log -w "Empty use ninja parameter"
            fi
          else
            log -w "No use ninja parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupNinja
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setupNinja.sh\" instead."
  exit 1
fi