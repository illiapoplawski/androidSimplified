#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the build top directory
#/
#/  Public Functions:
#/
#/ Usage: setTopDir [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/
#/ EXAMPLES
#/   setTopDir
#/   setTopDir -d <path>
#/   setTopDir --help
#/

# Ensures script is only sourced once
if [[ ${SET_TOP_DIR_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_TOP_DIR_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_TOP_DIR_SCRIPT_NAME ]]  || readonly SET_TOP_DIR_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_TOP_DIR_SCRIPT_DIR ]]  || readonly SET_TOP_DIR_SCRIPT_DIR="$( cd "$( dirname "$SET_TOP_DIR_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SET_TOP_DIR_SCRIPT_DIR"/logging.sh

# Usage: _setTopDir
#
# Sets the build top dir
_setTopDir() {
  if [[ ! -v BUILD_TOP_DIR || -z $BUILD_TOP_DIR || $BUILD_TOP_DIR == " " || ! -d $BUILD_TOP_DIR ]]; then
    if BUILD_TOP_DIR=$( "$SET_TOP_DIR_SCRIPT_DIR"/userFunctions.sh getDir -t "Choose your android source directory" -o "$HOME"); then
      log -i "Android Top Directory set to $BUILD_TOP_DIR"
    else
      log -e "Android Top Directory not specified"
      return 1
    fi
  fi

  if [[ ! -d $BUILD_TOP_DIR ]]; then
    log -e "Android Top Directory: $BUILD_TOP_DIR does not exist."
    return 1
  fi
  
  BUILD_TOP_DIR=${BUILD_TOP_DIR%/}
  export BUILD_TOP_DIR
}

# Show set build top dir usage
_setTopDirUsage() {
  grep '^#/' "${SET_TOP_DIR_SCRIPT_DIR}/${SET_TOP_DIR_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setTopDir [arg]
#
# Sets the build top dir
setTopDir(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setTopDir
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help) 
          shift
          _setTopDirUsage
          return 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ $dir != '-'* ]]; then
            shift # past value
            if [[ -n $dir ]]; then
              BUILD_TOP_DIR="$dir"
            else 
              log -w "No base directory parameter specified"
            fi
          fi
          ;;
        *) log -e "Unknown arguments passed:$action:"; _setTopDirUsage; return 128 ;;
      esac
    done
    _setTopDir
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setTopDir.sh\" instead."
  exit 1
fi