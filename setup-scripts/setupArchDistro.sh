#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the required packages for building Android on Arch Distros
#/
#/  Public Functions:
#/
#/ Usage: $setupArchDistro [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupArchDistro
#/   setupArchDistro --help
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupArchDistro
#
# Installs the required packages for building Android on Arch Distros
_setupArchDistro() {
  log -i "Updating package repositories"
  sudo pacman -Syyu
  
  log -i "Installing packages"
  sudo pacman --noconfirm -Sq base-devel wget multilib-devel cmake svn clang android-udev

  for package in ncurses5-compat-libs lib32-ncurses5-compat-libs aosp-devel xml2 lineageos-devel; do
    git clone https://aur.archlinux.org/"${package}.git"
    pushd "$package" &>/dev/null || continue
    makepkg -si --noconfirm
    popd &>/dev/null || break
    rm -rf "$package"
  done
  log -i "Packages installed"
}

# Show setup Arch Distro usage
_setupArchDistroUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupArchDistro [args]
#
# Installs the required packages for building Android on Arch Distros
setupArchDistro(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupArchDistro
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
          _setupArchDistroUsage
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupArchDistro
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupArchDistro.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupArchDistro "$@"