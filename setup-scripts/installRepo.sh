#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the latest version of repo
#/
#/  Public Functions:
#/
#/ Usage: $installRepo [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --version
#/                Returns the latest version of repo available
#/
#/ EXAMPLES
#/   installRepo
#/   installRepo --help
#/   installRepo -v
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh

_localRepoVer() {
  verifyPythonVenv -d /tmp &>/dev/null || exit $?
  if repo --version; then
    # repo installed and initialized
    repo --version | grep -e 'repo launcher version ' | sed -e 's/repo launcher version //'
  else
    # repo installed but not initialized
    loc=$(whereis repo)
    loc="${loc##* }"
    grep '^VERSION = ' "$loc" | sed -e 's/VERSION = (//' -e 's/)//' -e 's/, /./'
  fi
  rm -rf /tmp/venv
}

# Usage: _latestRepoVer
#
# Returns the latest version of repo available
_latestRepoVer() {
  curl -s https://storage.googleapis.com/git-repo-downloads/repo | grep '^VERSION = ' | sed -e 's/.*(//' -e 's/).*//' -e 's/, /./'
}

# Usage: _installRepo
#
# Installs the latest version of repo
_installRepo() {
  local latestVer
  latestVer=$(_latestRepoVer)
  command -v repo &>/dev/null && {
    if [[ "$(_localRepoVer)" == "$latestVer" ]]; then
      log -i "Latest Repo version already installed: $latestVer"
      exit 0
    fi
  }
  log -i "Installing the latest version of Repo"

  sudo curl -s --create-dirs -o /usr/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
  sudo chmod a+x /usr/bin/repo
  log -i "Repo $latestVer installed"
}

# Show install Repo usage
_installRepoUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installRepo [args]
#
# Installs the latest version of repo
installRepo(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _installRepo
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
          _installRepoUsage
          exit 0
          ;;
        -v|--version)
          shift
          _latestRepoVer
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installRepo
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installRepo.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installRepo "$@"