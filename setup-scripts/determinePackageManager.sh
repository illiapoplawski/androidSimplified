#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Determines the package manager running in OS
#/
#/  Public Functions:
#/
#/ Usage: $determinePackageManager [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   determinePackageManager
#/   determinePackageManager --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _determinePackageManager
#
# Determine the package manager running in OS
_determinePackageManager() {
  # Fedora (redhat): yum, dnf, rpm
  # CentOS (redhat): yum, rpm
  # OpenSUSE: zyper, rpm
  # Mint, Ubuntu (Debian Based): dpkg, apt
  # Arch: pacman
  case $(uname) in
    Linux )
      command -v yum &>/dev/null && { echo centos; } # rpm based
      command -v dnf &>/dev/null && { echo fedora; } # rpm based
      command -v zypper &>/dev/null && { echo opensuse; }
      command -v dpkg &>/dev/null && { echo debian; }
      command -v apt &>/dev/null && { echo apt; } # dpkg based
      command -v pacman &>/dev/null && { echo arch; }
      command -v portage &>/dev/null && { echo gentoo; }
      command -v rpm &>/dev/null && { echo redhat; } 
      ;;
    Darwin )
      # Mac
      ;;
    * )
      # Handle AmgiaOS, CPM, and modified cable modems here.
      ;;
  esac
}

# Show determine Package Manager usage
_determinePackageManagerUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: determinePackageManager
#
# Determine package manager running in OS
determinePackageManager(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _determinePackageManager
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
          _determinePackageManagerUsage
          exit 0
         ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _determinePackageManager
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./determinePackageManager.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && determinePackageManager "$@"
