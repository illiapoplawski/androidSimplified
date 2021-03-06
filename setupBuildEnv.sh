#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: setupBuildEnv [OPTIONS]...
#/
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/   -n, --name
#/                The user name for Git
#/   -e, --email
#/                The user email for Git
#/
#/ EXAMPLES
#/   setupBuildEnv -h
#/   setupBuildEnv -n "Full Name" -e "email"
#/  

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh

# Usage: _setupBuildEnv
#
# Sets up the computer for building Android ROMs
_setupBuildEnv() {
  local curOS
  curOS=$("$SCRIPT_DIR"/setup-scripts/determineOS.sh)
  local tmp=${curOS%%, ver: *}
  local name=${tmp##os: }
  case $name in
    "Ubuntu"|"ubuntu"|"Linux Mint"|"linuxmint" )
      "$SCRIPT_DIR"/setup-scripts/setupDebianDistro.sh
      ;;
    "Fedora"|"fedora"|"CentOS Linux"|"centos" )
      "$SCRIPT_DIR"/setup-scripts/setupRedHatDistro.sh
      ;;
    "openSUSE Tumbleweed"|"opensuse-tumbleweed" )
      "$SCRIPT_DIR"/setup-scripts/setupSuseDistro.sh
      ;;
    "Manjaro Linux"|"manjaro" )
      "$SCRIPT_DIR"/setup-scripts/setupArchDistro.sh
      ;;
    * )
      # Handle AmgiaOS, CPM, and modified cable modems here.
      log -i "Your current distro is currently not yet supported.  Feel free to ensure all the required packages get installed then add it to the list!"
      ;;
  esac

  "$SCRIPT_DIR"/setup-scripts/setupGit.sh -n "$user_name" -e "$user_email"
}

# Show setup build environment usage
_setupBuildEnvUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupBuildEnv [args]
#
# Sets up the computer for building Android ROMs
setupBuildEnv(){
  local user_email
  local user_name

  local action
  while [[ $# -gt 0 ]]; do
    action="$1"
    if [[ "$action" != '-'* ]]; then
      shift
      continue
    fi
    case "$action" in
      -h|--help)
        shift
        _setupBuildEnvUsage
        exit 0
        ;;
      -e|--email)
        local email="$2"
        shift # past argument
        if [[ "$email" != '-'* ]]; then
          shift # past value
          if [[ -n $email && "$email" != " " ]]; then
            user_email="$email"
          else
            log -w "Empty user email parameter"
          fi
        else
          log -w "No user email parameter specified"
        fi
        ;;
      -n|--name)
        local name="$2"
        shift # past argument
        if [[ "$name" != '-'* ]]; then
          shift # past value
          if [[ -n $name && "$name" != " " ]]; then
            user_name="$name"
          else
            log -w "Empty user name parameter"
          fi
        else
          log -w "No user name parameter specified"
        fi
        ;;
      *) log -w "Unknown argument passed: $action. Skipping"
        shift # past argument
        ;;
    esac
  done

  # Check mandatory params set
  if [[ ! -v user_email || ! -v user_name ]]; then
    log -e "User email and user name must be specified for git"
    _setupBuildEnvUsage
    exit 1
  fi
  _setupBuildEnv
}

err_report() {
    local lineNo=$1
    local msg=$2
    echo "Error on line $lineNo: $msg"
    exit 1
}

trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupBuildEnv.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupBuildEnv "$@"
