#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up git
#/
#/  Public Functions:
#/
#/ Usage: $setupGit [argument]
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
#/   setupGit
#/   setupGit --help
#/   setupGit -e "email" -n "name"
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupGit
#
# Sets up git
_setupGit() {
  if [[ ! -v user_name ]]; then
    user_name=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Setup Git" -d "Enter your name" ) || {
      log -e "User name input cancelled by user"
      exit $?
    }
  fi
  log -i "Git user name set to: $user_name"
  git config --global user.name "$user_name"

  if [[ ! -v user_email ]]; then
    user_email=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Setup Git" -d "Enter your email" ) || {
      log -e "User email input cancelled by user"
      exit $?
    }
  fi
  log -i "Git user email set to: $user_email"
  git config --global user.email "$user_email"

  # Setup SSH
  "$SCRIPT_DIR"/setupSsh.sh -e "$user_email"
}

# Show setup Git usage
_setupGitUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupGit [args]
#
# Sets up git
setupGit(){
  local user_email
  local user_name

  local action
  if [[ ${#} -eq 0 ]]; then
    _setupGit
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
          _setupGitUsage
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
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupGit
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupGit.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupGit "$@"