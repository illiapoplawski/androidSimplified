#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the device name to build
#/
#/  Public Functions:
#/
#/ Usage: setDeviceName [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -n, --name <name>
#/                Device Name to build
#/
#/ EXAMPLES
#/   setDeviceName
#/   setDeviceName -n <device name>
#/   setDeviceName --help
#/

# Ensures script is only sourced once
if [[ ${SET_DEVICE_NAME_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_DEVICE_NAME_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_DEVICE_NAME_SCRIPT_NAME ]]  || readonly SET_DEVICE_NAME_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_DEVICE_NAME_SCRIPT_DIR ]]  || readonly SET_DEVICE_NAME_SCRIPT_DIR="$( cd "$( dirname "$SET_DEVICE_NAME_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_DEVICE_NAME_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setDeviceName
#
# Sets the device name
_setDeviceName() {
  if [[ ( ! -v DEVICE_NAME || -z $DEVICE_NAME || "$DEVICE_NAME" == " " ) &&
        ( ! -v device_name || -z $device_name || "$device_name" == " " ) ]]; then
    if device_name=$("$(dirname "$SET_DEVICE_NAME_SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Build Image" -d "Enter the device code name" -i "angler"); then
      if [[ ! -v device_name || -z $device_name || "$device_name" == " " ]]; then
        log -e "Device name not specified"
        exit 1
      else
        log -i "Device name set to $device_name"
      fi
    else
      log -e "Setting device name cancelled by user"
      exit 1
    fi
  fi
  export DEVICE_NAME="$device_name"
}

# Show set device name usage
_setDeviceNameUsage() {
  grep '^#/' "${SET_DEVICE_NAME_SCRIPT_DIR}/${SET_DEVICE_NAME_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setDeviceName [arg]
#
# Sets the device name
setDeviceName(){
  local device_name

  local action
  if [[ ${#} -eq 0 ]]; then
    _setDeviceName
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
          _setDeviceNameUsage
          return 0
          ;;
        -n|--name)
          local nam="$2"
          shift # past argument
          if [[ "$nam" != '-'* ]]; then
            shift # past value
            if [[ -n $nam && "$nam" != " " ]]; then
              device_name="$nam"
            else
              log -w "Empty device name parameter"
            fi
          else
            log -w "No device name parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setDeviceName
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setDeviceName.sh\" instead."
  exit 1
fi