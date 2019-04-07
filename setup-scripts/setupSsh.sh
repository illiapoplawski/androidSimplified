#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up git
#/
#/  Public Functions:
#/
#/ Usage: $setupSsh [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -e, --email
#/                The user email for Git
#/   -d, --dir
#/                The directory to store ssh keys
#/
#/ EXAMPLES
#/   setupSsh
#/   setupSsh --help
#/   setupSsh -e "email" -d "out dir"
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupSsh
#
# Sets up ssh
_setupSsh() {
  if [[ -v out_dir ]]; then
    out_dir=${out_dir%/}
    out_dir="$out_dir/.ssh"
  else
    out_dir="$HOME/.ssh"
  fi

  if [[ $(find "$out_dir" -type f | grep -c "id_*") -ge 2 ]]; then
    log -i "SSH key already setup."
  else
    if [[ ! -v user_email ]]; then
      log -i "request email"
      user_email=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Setup SSH" -d "Enter your email") || {
        log -e "User email input cancelled by user"
        exit 1
      }
    fi
    log -i "Email: $user_email"
    
    local out_dir
    out_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose where to save your ssh files" -o "$HOME") || {
      log -e "SSh output directory selection cancelled by user"
      exit 1
    }
    out_dir="$out_dir/.ssh"
    log -i "SSH key dir: $out_dir"
    mkdir -p "$out_dir"

    local sshPass=first
    local secondPass=secondPass
    while [[ "$sshPass" != "$secondPass" ]]; do
      sshPass=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getPassword -t "SSH Password" -d "Enter your password and choose Ok to continue.") || {
        log -e "Entering ssh key password cancelled by user"
        exit 1
      }
      secondPass=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getPassword -t "SSH Password" -d "Re-enter your password and choose Ok to continue.") || {
        log -e "Entering ssh key password cancelled by user"
        exit 1
      }
    done

    ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$out_dir"/id_rsa -N "$sshPass"
    chmod u=r "$out_dir"/id_rsa
  fi

  # copy key to clipboard
  log -i "Copy the below public key into your Gerrit SSH Keys"
  cat "$out_dir"/id_rsa.pub
}

# Show setup SSH usage
_setupSshUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupSsh [args]
#
# Sets up ssh
setupSsh(){
  local user_email
  local out_dir

  local action
  if [[ ${#} -eq 0 ]]; then
    _setupSsh
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
          _setupSshUsage
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
        -d|--outdir)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              out_dir="$dir"
            else
              log -w "Empty ssh key directory parameter"
            fi
          else
            log -w "No ssh key directory parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupSsh
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupSsh.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupSsh "$@"