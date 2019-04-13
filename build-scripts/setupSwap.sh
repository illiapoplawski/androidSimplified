#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up Swap
#/
#/  Public Functions:
#/
#/ Usage: swap [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -a, --auto
#/                Automatically disables swap (recommended for building AOSP)
#/
#/ EXAMPLES
#/   setupSwap
#/   setupSwap -a
#/   setupSwap -h
#/  

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

_checkSwapOn(){
  if [[ $(swapon --show | wc -l) -gt 1 ]] ; then
    # Swap on
    return 0
  else
    # Swap off
    return 1
  fi
}

# Usage: _disableSwapQuiet
#
# Disables all swap areas quietly
_disableSwapQuiet() {
  sudo swapoff -a
}

# Usage: _disableSwap
#
# Disables all swap areas
_disableSwap() {
  log -i "Disabling swap"
  _disableSwapQuiet
}

# Usage: _enableSwapQuiet
#
# Enables all swap areas quietly
_enableSwapQuiet() {
  sudo swapon -a
}

# Usage: _enableSwap
#
# Enables all swap areas
_enableSwap() {
  log -i "Enabling swap"
  _enableSwapQuiet
}

# Usage: _grabSudoGUI
#
# Grabs sudo through GUI for commands
_grabSudoGUI() {
  export HISTIGNORE='*sudo -S*'
  if [[ $(id -u) -ne 0 ]] ; then 
    local psw
    psw=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getPassword -t "Sudo Password" -d "Enter your password and choose Ok to continue.") || {
      log -e "Elevating to sudo cancelled by user"
      return 1
    }

    # Elevate to sudo after receiving password from user
    echo "$psw" | sudo -Ss &>/dev/null || _grabSudoGUI
  fi
}

# Usage: _clearSudoCredentials
#
# Clears sudo credentials after running GUI commands.  They break otherwise on re-requesting creds
_clearSudoCredentials() {
  sudo -k
}

# Usage: _setupSwap
#
# Sets up swap based on user decision or on automatic settings
_setupSwap(){
  if _checkSwapOn; then
    # Swap is on
    if [[ "$enable_swap" == "false" ]]; then
      _disableSwap
    elif [[ "$enable_swap" == "true" ]]; then
      log -i "Swap is already enabled"
    else
      if "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Setup Swap" -d "Would you like to disable swap?\nIt is recommended to disable it for building AOSP."; then
        _grabSudoGUI || exit $?
        _disableSwap
        _clearSudoCredentials
      else
        log -w "Leaving swap enabled"
      fi
    fi
  else
    # Swap is off
    if [[ "$enable_swap" == "false" ]]; then
      log -i "Swap is already disabled"
    elif [[ "$enable_swap" == "true" ]]; then
      _enableSwap
    else
      if "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Setup Swap" -d "Swap is currently disabled.  Would you like to enable swap?\nIt is recommended to leave it disabled it for building AOSP and re-enable it afterwards." -i "no"; then
        _grabSudoGUI || exit $?
        log -w "Enabling swap"
        _enableSwapQuiet
        _clearSudoCredentials
      else
        log -i "Leaving swap disabled"
      fi
    fi
  fi
}

# Show setup swap usage info
_setupSwapUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupSwap [arg]
#
# Sets up swap for building AOSP
setupSwap(){
  local enable_swap

  local action
  if [[ ${#} -eq 0 ]]; then
    _setupSwap
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
            _setupSwapUsage
            return 0
          ;;
          -e|--enable) 
            local value="$2"
            shift # past argument
            if [[ "$value" != '-'* ]]; then
              shift # past value
              if [[ -n $value && "$value" != " " ]]; then
                if [[ "$value" = "true" || "$value" = "false" ]]; then
                  enable_swap="$value"
                else
                  log -e "Unknown arguments passed"; _setupSwapUsage; return 128
                fi
              else
                log -w "Empty enable swap parameter"
              fi
            else
              log -w "No enable swap parameter specified"
            fi
            ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupSwap
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupSwap.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupSwap "$@"
