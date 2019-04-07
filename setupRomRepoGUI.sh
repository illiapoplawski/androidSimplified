#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: setupRomRepoGUI [OPTIONS]... [ARGUMENTS]...
#/ 
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupRomRepoGUI -h
#/ 

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh
. "$SCRIPT_DIR"/utilities/setTopDir.sh
. "$SCRIPT_DIR"/utilities/verifyPythonVenv.sh

# Usage: _setupRomRepoGUI
#
# Sets up a rom repo GUI for building
_setupRomRepoGUI() {
  # Set build top dir
  setTopDir -d "$top_dir" || exit $?

  # Enable Python 2.7 virtual environment
  verifyPythonVenv || exit $?

  # Init repo
  "$SCRIPT_DIR"/setup-scripts/initRomRepo.sh || exit $?

  # Sync repo
  "$SCRIPT_DIR"/build-scripts/syncRepo.sh || exit $?
}

# Show setup rom repo GUI usage
_setupRomRepoGUIUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupRomRepoGUI [args]
#
# Sets up a rom repo for building
setupRomRepoGUI(){
  local action
  while [[ $# -gt 0 ]]; do
    action="$1"
    case "$action" in
      -h|--help)
        shift
        _setupRomRepoGUIUsage
        exit 0
        ;;
      *) log -e "Unknown arguments passed"; _setupRomRepoGUIUsage; exit 128 ;;
    esac
  done
  _setupRomRepoGUI
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
  log -e "This script cannot be sourced. Use \"./setupRomRepoGUI.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupRomRepoGUI "$@"
