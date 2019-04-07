#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of flex
#/
#/  Public Functions:
#/
#/ Usage: $installFlex [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of flex available
#/
#/ EXAMPLES
#/   installFlex
#/   installFlex --help
#/   installFlex -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localFlexVersion() {
  local version
  version=$(flex -V | grep 'flex ')
  echo "${version##"flex "}"
}

# Usage: _latestFlexVer
#
# Returns the latest version of flex available
_latestFlexVer() {
  git ls-remote --tags https://github.com/westes/flex | 
      tail -n1 | sed -e 's/.*\///' -e 's/\^{}//' -e 's/v//'
}

# Usage: _installFlex
#
# Installs the latest version of flex
_installFlex() {
  local latestVer
  latestVer=$(_latestFlexVer)

  command -v flex &>/dev/null && {
    if [[ "$(_localFlexVersion)" == "$latestVer" ]]; then
      log -i "Latest flex version already installed: $latestVer"
      exit 0
    fi
  }

  log -i "Installing the latest version of flex"
  pushd /tmp &>/dev/null || exit $?
  git clone https://github.com/westes/flex.git
  pushd /tmp/flex &>/dev/null || exit $?
  ./autogen.sh
  ./configure --prefix=/usr
  make -j"$("$(dirname "$SCRIPT_DIR")"/utilities/totalCpu.sh)"
  sudo make install
  popd &>/dev/null || exit $?
  rm -rf flex
  popd &>/dev/null || exit $?
  log -i "flex $latestVer installed"
}

# Show install flex usage
_installFlexUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installFlex [args]
#
# Installs the latest version of flex
installFlex(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installFlex
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
          _installFlexUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestFlexVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installFlex
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installFlex.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installFlex "$@"