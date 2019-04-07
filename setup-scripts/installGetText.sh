#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of gettext
#/
#/  Public Functions:
#/
#/ Usage: $installGetText [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of gettext available
#/
#/ EXAMPLES
#/   installGetText
#/   installGetText --help
#/   installGetText -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localGetTextVersion() {
  local version
  version=$(gettext -V | grep 'gettext (GNU gettext-runtime)')
  echo "${version##"gettext (GNU gettext-runtime) "}"
}

# Usage: _latestGetTextVer
#
# Returns the latest version of gettext available
_latestGetTextVer() {
  curl -s 'https://ftp.gnu.org/pub/gnu/gettext/' | 
    grep -oP 'href="gettext-\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | 
    sort -t. -rn -k1,1 -k2,2 -k3,3 -k4,4 | head -1
}

# Usage: _installGetText
#
# Installs the latest version of gettext
_installGetText() {
  local latestVer
  latestVer=$(_latestGetTextVer)

  command -v gettext &>/dev/null && {
    if [[ "$(_localGetTextVersion)" == "$latestVer" ]]; then
      log -i "Latest Get Text version already installed: $latestVer"
      exit 0
    fi
  }

  log -i "Installing the latest version of Get Text"
  pushd /tmp &>/dev/null || exit $?
  curl -s "https://ftp.gnu.org/pub/gnu/gettext/gettext-${latestVer}.tar.gz" > /tmp/gettext-"${latestVer}".tar.gz
  tar xzf /tmp/gettext-"${latestVer}".tar.gz
  pushd /tmp/gettext-"$latestVer" &>/dev/null || exit $?
  ./configure --prefix=/usr
  make
  sudo make install
  popd &>/dev/null || exit $?
  rm -rf /tmp/gettext-"$latestVer"{,.tar.gz}
  popd &>/dev/null || exit $?
  log -i "Get Text $latestVer installed"
}

# Show install Get Text usage
_installGetTextUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installGetText [args]
#
# Installs the latest version of gettext
installGetText(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installGetText
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
          _installGetTextUsage
          exit 0
          ;;
        -v|--version)
          shift
          _localGetTextVersion
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installGetText
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installGetText.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installGetText "$@"