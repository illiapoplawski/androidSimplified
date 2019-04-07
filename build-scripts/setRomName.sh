#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the rom name to build
#/
#/  Public Functions:
#/
#/ Usage: setRomName [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -n, --name <name>
#/                ROM Name to build
#/
#/ EXAMPLES
#/   setRomName
#/   setRomName -n <rom name>
#/   setRomName --help
#/

# Ensures script is only sourced once
if [[ ${SET_ROM_NAME_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_ROM_NAME_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_ROM_NAME_SCRIPT_NAME ]]  || readonly SET_ROM_NAME_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_ROM_NAME_SCRIPT_DIR ]]  || readonly SET_ROM_NAME_SCRIPT_DIR="$( cd "$( dirname "$SET_ROM_NAME_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_ROM_NAME_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setRomName
#
# Sets the rom name
_setRomName() {
  if [[ ( ! -v ROM_NAME || -z $ROM_NAME || "$ROM_NAME" == " " ) &&
        ( ! -v rom_name || -z $rom_name || "$rom_name" == " " ) ]]; then
    if rom_name=$("$(dirname "$SET_ROM_NAME_SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Set Rom Name" -d "Enter the ROM name" -i "statix"); then
      if [[ ! -v rom_name || -z $rom_name || "$rom_name" == " " ]]; then
        log -e "ROM name not specified"
        return 1
      else
        log -i "Rom name set to $rom_name"
      fi
    else
      log -e "Setting ROM name cancelled by user"
      return 1
    fi
  fi
  export ROM_NAME="$rom_name"
}

# Show set rom name usage
_setRomNameUsage() {
  grep '^#/' "${SET_ROM_NAME_SCRIPT_DIR}/${SET_ROM_NAME_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setRomName [arg]
#
# Sets the rom name
setRomName(){
  local rom_name

  local action
  if [[ ${#} -eq 0 ]]; then
    _setRomName
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
          _setRomNameUsage
          return 0
          ;;
        -n|--name)
          local nam="$2"
          shift # past argument
          if [[ "$nam" != '-'* ]]; then
            shift # past value
            if [[ -n $nam && "$nam" != " " ]]; then
              rom_name="$nam"
            else
              log -w "Empty rom name parameter"
            fi
          else
            log -w "No rom name parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setRomName
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setRomName.sh\" instead."
  exit 1
fi