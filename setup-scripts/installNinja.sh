#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of ninja
#/
#/  Public Functions:
#/
#/ Usage: $installNinja [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of ninja available
#/
#/ EXAMPLES
#/   installNinja
#/   installNinja --help
#/   installNinja -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_localNinjaVer() {
  ninja --version
}

# Usage: _latestNinjaVer
#
# Returns the latest version of ninja available
_latestNinjaVer() {
  curl -s 'https://raw.githubusercontent.com/ninja-build/ninja/master/src/version.cc' |
    grep "kNinjaVersion = " | cut -d '"' -f 2
}

# Usage: _installNinja
#
# Installs the latest version of ninja
_installNinja() {
  local latestVer
  latestVer=$(_latestNinjaVer)
  command -v ninja &>/dev/null && {
    if [[ "$(_localNinjaVer)" == "$latestVer" ]]; then
      log -i "Latest Ninja version already installed: $latestVer"
      exit 0
    fi
  }
  log -i "Installing the latest version of Ninja"

  pushd /tmp &>/dev/null || exit $?
  git clone https://github.com/ninja-build/ninja.git
  pushd /tmp/ninja &>/dev/null || exit $?
  ./configure.py --bootstrap
  sudo install ./ninja /usr/bin/ninja
  popd &>/dev/null || exit $?
  rm -rf ninja
  popd &>/dev/null || exit $?
  log -i "Ninja $latestVer installed"
}

# Show install Ninja usage
_installNinjaUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installNinja [args]
#
# Installs the latest version of ninja
installNinja(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installNinja
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
          _installNinjaUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestNinjaVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installNinja
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installNinja.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installNinja "$@"