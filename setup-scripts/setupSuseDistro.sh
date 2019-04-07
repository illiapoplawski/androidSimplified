#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the required packages for building Android on OpenSUSE Distros
#/
#/  Public Functions:
#/
#/ Usage: $setupSuseDistro [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupSuseDistro
#/   setupSuseDistro --help
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupSuseDistro
#
# Installs the required packages for building Android on OpenSUSE Distros
_setupSuseDistro() {
  log -i "Updating package repositories"
  sudo zypper refresh
  
  log -i "Installing packages"
  sudo zypper -n rm openjdk-* icedtea-* icedtea6-*
  sudo zypper -n in -t pattern devel_basis
  sudo zypper -n in java-1_8_0-openjdk java-1_8_0-openjdk-devel SDL-devel python-wxWidgets-devel \
    lzop schedtool squashfs glibc-devel-32bit ncurses-devel-32bit ncurses5-devel-32bit readline-devel-32bit \
    ccache libz1-32bit python-xml bc gpg2 liblz4-1 libxml2-2 libxml2-tools libxslt-tools zip clang wget ffmpeg \
    ninja pngcrush

  "$SCRIPT_DIR"/installRepo.sh
  log -i "Packages installed"
}

# Show setup OpenSUSE Distro usage
_setupSuseDistroUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupSuseDistro [args]
#
# Installs the required packages for building Android on OpenSUSE Distros
setupSuseDistro(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupSuseDistro
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
          _setupSuseDistroUsage
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupSuseDistro
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupSuseDistro.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupSuseDistro "$@"