#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Verifies that python2.7 is set to be used by repopick
#/
#/  Public Functions:
#/
#/ Usage: $verifyPythonVenv [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/
#/ EXAMPLES
#/   verifyPythonVenv
#/   verifyPythonVenv -d <path/to/root/dir>
#/   verifyPythonVenv -h
#/

# Ensures script is only sourced once
if [[ ${VERIFY_PYTHON_GUARD:-} -eq 1 ]]; then
  return
else
  readonly VERIFY_PYTHON_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v VERIFY_PYTHON_SCRIPT_NAME ]]  || readonly VERIFY_PYTHON_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v VERIFY_PYTHON_SCRIPT_DIR ]]  || readonly VERIFY_PYTHON_SCRIPT_DIR="$( cd "$( dirname "$VERIFY_PYTHON_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$VERIFY_PYTHON_SCRIPT_DIR"/logging.sh
. "$VERIFY_PYTHON_SCRIPT_DIR"/setTopDir.sh

## each separate version number must be less than 3 digit wide !
_version() { 
  echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

# Usage: _verifyPythonVenv
#
# Ensures that python2.7 is used for repopick
_verifyPythonVenv() {
  log -i "Verifying python2.7 venv"
  version=$(python -V |& grep -Po '(?<=Python )(.+)')
  if [[ -z $version ]]; then
    log -e "Python is not installed!"
    return 1
  fi
  
  if [[ "$(_version "$version")" -lt "003000000" ]]; then
    log -i "Correct Python version setup"
    return 0
  fi

  log -w "Invalid Python version setup.  Initializing Python2 virtual environment"
  setTopDir -d "$BUILD_TOP_DIR" || {
    local ret=$?
    log -e "Build top directory not set. Exiting."
    return $ret
  }

  # Setup virtual environment for Python2
  pushd "$BUILD_TOP_DIR" &>/dev/null || return $?
  if [[ ! -f venv/bin/activate ]]; then
    virtualenv2 venv
  fi
  # Activate Python2 virtual environment
  log -i "Activating Python 2.7 virtual environment"
  . venv/bin/activate
  log -i "Python 2.7 virtual environment setup"
  popd &>/dev/null || return $?
}

# Show verify python venv usage
_verifyPythonVenvUsage() {
  grep '^#/' "${VERIFY_PYTHON_SCRIPT_DIR}/${VERIFY_PYTHON_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: verifyPythonVenv [arg]
#
# Ensures that python2.7 is used for repopick
verifyPythonVenv(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _verifyPythonVenv
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help) 
          shift
          _verifyPythonVenvUsage
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
        *) log -e "Unknown arguments passed $action"; _verifyPythonVenvUsage; return 128 ;;
      esac
    done
    _verifyPythonVenv
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./verifyPythonVenv.sh\" instead."
  exit 1
fi