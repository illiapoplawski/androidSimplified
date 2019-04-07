#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of make
#/
#/  Public Functions:
#/
#/ Usage: $installMake [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of make available
#/
#/ EXAMPLES
#/   installMake
#/   installMake --help
#/   installMake -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localMakeVersion() {
  local version
  version=$(make -v | grep 'GNU Make')
  echo "${version##"GNU Make "}"
}

# Usage: _latestMakeVer
#
# Returns the latest version of make available
_latestMakeVer() {
  curl -s 'https://ftp.gnu.org/gnu/make/' | 
    grep -oP 'href="make-\K[0-9]+\.[0-9]+\.[0-9]+' | 
    sort -t. -rn -k1,1 -k2,2 -k3,3 | head -1
}

# Usage: _installMake
#
# Installs the latest version of make with a a glic patch
_installMake() {
  local latestVer
  latestVer=$(_latestMakeVer)

  command -v make &>/dev/null && {
    if [[ "$(_localMakeVersion)" == "$latestVer" ]]; then
      log -i "Latest Make version already installed: $latestVer"
      exit 0
    fi
  }

  log -i "Installing the latest version of Make"
  pushd /tmp &>/dev/null || exit $?
  curl -s "https://ftp.gnu.org/gnu/make/make-${latestVer}.tar.gz" > /tmp/make-"${latestVer}".tar.gz
  tar xzf /tmp/make-"${latestVer}".tar.gz
  pushd /tmp/make-"$latestVer" &>/dev/null || exit $?
  ./configure --prefix=/usr
  curl -s https://raw.githubusercontent.com/akhilnarang/scripts/master/patches/make-glibc_alloc_fix.patch | patch -p1
  bash ./build.sh
  sudo install ./make /usr/bin/make
  popd &>/dev/null || exit $?
  rm -rf /tmp/make-"$latestVer"{,.tar.gz}
  popd &>/dev/null || exit $?
  log -i "Make $latestVer installed"
}

# Show install Make usage
_installMakeUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installMake [args]
#
# Installs the latest version of make with a a glic patch
installMake(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installMake
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
          _installMakeUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestMakeVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installMake
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installMake.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installMake "$@"