#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Determines the current running OS
#/
#/  Public Functions:
#/
#/ Usage: $determineOS [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   determineOS
#/   determineOS --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _determineOS
#
# Determine the current running OS
# Modern distros mostly all follow the standard of /etc/os-release
_determineOS() {
    # COMMON RETURNS: 
    # name: Ubuntu, id: ubuntu, ver: 14.04
    # name: Ubuntu, id: ubuntu, ver: 16.04
    # name: Ubuntu, id: ubuntu, ver: 18.04
    # name: Fedora, id: fedora, ver: 29
    # name: openSUSE Tumbleweed, id: opensuse-tumbleweed, ver: 20190327
    # name: CentOS Linux, id: centos, ver: 7
    # name: Linux Mint, id: linuxmint, ver: 18.3
    # name: Linux Mint, id: linuxmint, ver: 19.1
    # name: Manjaro Linux, id: manjaro, ver: 
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    # All the common returns triggered on this flag
    . /etc/os-release
    OS=$NAME # or $ID
    VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi
  echo "os: $OS, ver: $VER"
}

# Show determine OS usage
_determineOSUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: determineOS
#
# Determine current running OS
determineOS(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _determineOS
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
          _determineOSUsage
          exit 0
         ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _determineOS
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./determineOS.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && determineOS "$@"
