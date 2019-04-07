#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: setupBuildEnv [OPTIONS]...
#/
#/ 
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupBuildEnv -h
#/   setupBuildEnv
#/  

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh

# Usage: _setupBuildEnv
#
# Sets up the computer for building Android ROMs
_setupBuildEnv() {
  local curOS
  curOS=$("$SCRIPT_DIR"/setup-scripts/determineOS.sh)
  local tmp=${curOS%%, ver: *}
  local name=${tmp##os: }
  case $name in
    "Ubuntu"|"ubuntu"|"Linux Mint"|"linuxmint" )
      "$SCRIPT_DIR"/setup-scripts/setupDebianDistro.sh
      ;;
    "Fedora"|"fedora"|"CentOS Linux"|"centos" )
      "$SCRIPT_DIR"/setup-scripts/setupRedHatDistro.sh
      ;;
    "openSUSE Tumbleweed"|"opensuse-tumbleweed" )
      "$SCRIPT_DIR"/setup-scripts/setupSuseDistro.sh
      ;;
    "Manjaro Linux"|"manjaro" )
      "$SCRIPT_DIR"/setup-scripts/setupArchDistro.sh
      ;;
    * )
      # Handle AmgiaOS, CPM, and modified cable modems here.
      log -i "Your current distro is currently not yet supported.  Feel free to ensure all the required packages get installed then add it to the list!"
      ;;
  esac
}

# Show setup build environment usage
_setupBuildEnvUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupBuildEnv [args]
#
# Sets up the computer for building Android ROMs
setupBuildEnv(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupBuildEnv
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help)
          shift
          _setupBuildEnvUsage
          exit 0
         ;;
        *) log -e "Unknown arguments passed"; _setupBuildEnvUsage; exit 128 ;;
      esac
    done
    _setupBuildEnv
  fi
}

err_report() {
    local lineNo=$1
    local msg=$2
    echo "Error on line $lineNo: $msg"
    exit 1
}

trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupBuildEnv.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupBuildEnv "$@"
