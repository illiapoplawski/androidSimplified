#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of automake
#/
#/  Public Functions:
#/
#/ Usage: $installAutoMake [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of make available
#/
#/ EXAMPLES
#/   installAutoMake
#/   installAutoMake --help
#/   installAutoMake -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localAutoMakeVersion() {
  local version
  version=$(automake --version | grep 'automake (GNU automake)')
  echo "${version##"automake (GNU automake) "}"
}

# Usage: _latestAutoMakeVer
#
# Returns the latest version of automake available
_latestAutoMakeVer() {
  curl -s 'https://ftp.gnu.org/gnu/automake/' | 
    grep -oP 'href="automake-\K[0-9]+\.[0-9]+\.[0-9]+' | 
    sort -t. -rn -k1,1 -k2,2 -k3,3 | head -1
}

# Usage: _installAutoMake
#
# Installs the latest version of automake
_installAutoMake() {
  local latestVer
  latestVer=$(_latestAutoMakeVer)

  command -v make &>/dev/null && {
    if [[ "$(_localAutoMakeVersion)" == "$latestVer" ]]; then
      log -i "Latest automake version already installed: $latestVer"
      exit 0
    fi
  }

  log -i "Installing the latest version of automake"
  pushd /tmp &>/dev/null || exit $?
  curl -s "https://ftp.gnu.org/gnu/automake/automake-${latestVer}.tar.gz" > /tmp/automake-"${latestVer}".tar.gz
  tar xzf /tmp/automake-"${latestVer}".tar.gz
  pushd /tmp/automake-"$latestVer" &>/dev/null || exit $?
  ./configure --prefix=/usr
  make
  sudo make install
  popd &>/dev/null || exit $?
  rm -rf /tmp/automake-"$latestVer"{,.tar.gz}
  popd &>/dev/null || exit $?
  log -i "automake $latestVer installed"
}

# Show install automake usage
_installAutoMakeUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installAutoMake [args]
#
# Installs the latest version of automake
installAutoMake(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installAutoMake
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
          _installAutoMakeUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestAutoMakeVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installAutoMake
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installAutoMake.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installAutoMake "$@"