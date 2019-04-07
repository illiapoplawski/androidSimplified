#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Verifies that repopick is available to run and sources it if not already sourced
#/
#/  Public Functions:
#/
#/ Usage: $verifyRepopick [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/
#/ EXAMPLES
#/   verifyRepopick
#/   verifyRepopick -d <path/to/root/dir>
#/   verifyRepopick -h
#/

# Ensures script is only sourced once
if [[ ${VERIFY_REPOPICK_GUARD:-} -eq 1 ]]; then
  return
else
  readonly VERIFY_REPOPICK_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v VERIFY_REPOPICK_SCRIPT_NAME ]]  || readonly VERIFY_REPOPICK_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v VERIFY_REPOPICK_SCRIPT_DIR ]]  || readonly VERIFY_REPOPICK_SCRIPT_DIR="$( cd "$( dirname "$VERIFY_REPOPICK_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$VERIFY_REPOPICK_SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$VERIFY_REPOPICK_SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _verifyRepopick
#
# Verifies that repopick has been sourced and sources it if necessary
_verifyRepopick() {
  log -i "Verifying repopick exists"
  command -v repopick &>/dev/null || {
    log -i "Repopick must be sourced by running: source build/envsetup.sh from your source root dir.  Attempting to source automatically."
    setTopDir -d "$BUILD_TOP_DIR" || {
      log -e "Build top directory not set. Exiting."
      return 1
    }

    set -a
    . "$BUILD_TOP_DIR"/build/envsetup.sh
    set +a
    log -i "Repopick setup"
  }
}

# Show verify repopick usage

_verifyRepopickUsage() {
  grep '^#/' "${VERIFY_REPOPICK_SCRIPT_DIR}/${VERIFY_REPOPICK_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: verifyRepopick [arg]
#
# Verifies that repopick has been sourced and sources it if necessary
verifyRepopick(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _verifyRepopick
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help) 
          shift
          _verifyRepopickUsage
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
        *) log -e "Unknown arguments passed"; _verifyRepopickUsage; return 128 ;;
      esac
    done
    _verifyRepopick
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./verifyRepopick.sh\" instead."
  exit 1
fi