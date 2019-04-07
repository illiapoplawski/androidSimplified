#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of ccache
#/
#/  Public Functions:
#/
#/ Usage: $installCCache [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of ccache available
#/
#/ EXAMPLES
#/   installCCache
#/   installCCache --help
#/   installCCache -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localCCacheVersion() {
  local version
  version=$(ccache -V | grep 'ccache version')
  version=${version##"ccache version "}
  version=${version%+*}
  echo "${version##"ccache version "}"
}

# Usage: _latestCCacheVer
#
# Returns the latest version of ccache available
_latestCCacheVer() {
  git ls-remote --tags https://github.com/ccache/ccache | 
      tail -n1 | sed -e 's/.*\///' -e 's/\^{}//' -e 's/v//'
}

# Usage: _installCCache
#
# Installs the latest version of ccache
_installCCache() {
  local latestVer
  latestVer=$(_latestCCacheVer)

  command -v ccache &>/dev/null && {
    if [[ "$(_localCCacheVersion)" == "$latestVer" ]]; then
      log -i "Latest ccache version already installed: $latestVer"
      exit 0
    fi
  }

  log -i "Installing the latest version of ccache"
  pushd /tmp &>/dev/null || exit $?
  git clone https://github.com/ccache/ccache.git
  pushd /tmp/ccache &>/dev/null || exit $?
  ./autogen.sh
  ./configure --disable-man --prefix=/usr
  make -j"$("$(dirname "$SCRIPT_DIR")"/utilities/totalCpu.sh)"
  sudo make install
  popd &>/dev/null || exit $?
  rm -rf ccache
  popd &>/dev/null || exit $?
  log -i "ccache $latestVer installed"
}

# Show install ccache usage
_installCCacheUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installCCache [args]
#
# Installs the latest version of ccache
installCCache(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installCCache
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
          _installCCacheUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestCCacheVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installCCache
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installCCache.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installCCache "$@"