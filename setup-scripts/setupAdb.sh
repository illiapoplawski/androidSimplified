#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up ADB
#/
#/  Public Functions:
#/
#/ Usage: $setupAdb [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupAdb
#/   setupAdb --help
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupAdb
#
# Sets up ADB
_setupAdb() {
  command -v adb &>/dev/null && {
    local curOS
    curOS=$("$SCRIPT_DIR"/determineOS.sh)
    local tmp=${curOS%%, ver: *}
    local name=${tmp##os: }
    local ver=${curOS##* ver: }

    log -i "Setting up ADB udev rules"
    sudo curl -s --create-dirs -o /etc/udev/rules.d/51-android.rules https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
    sudo chmod a+r /etc/udev/rules.d/51-android.rules
    sudo groupdel adbusers
    sudo curl -s --create-dirs -o /usr/lib/sysusers.d/android-udev.conf https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/android-udev.conf
    sudo chmod a+r /usr/lib/sysusers.d/android-udev.conf

    if [[ "$name" == "Fedora" ]]; then
      groupadd adbusers # Fedora alternative
    elif [[ ( ("$name" == "Ubuntu" || "$name" == "ubuntu") && "$ver" == "16.04") || ( ("$name" == "Linux Mint" || "$name" == "linuxmint") && "$ver" == "18"*) ]]; then
      sudo groupadd adbusers # Ubuntu 16.04 or Mint 18
    else
      sudo systemd-sysusers # Ubuntu
    fi
    sudo usermod -a -G adbusers "$(whoami)"
    if [[ "$name" == "Fedora" ]]; then
      sudo systemctl restart systemd-udevd.service # Fedora
    elif [[ "$name" == "Ubuntu" ]]; then
      sudo udevadm control --reload-rules # ubuntu
      sudo service udev restart # ubuntu
    fi
    adb kill-server
  }
}

# Show setup ADB usage
_setupAdbUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupAdb [args]
#
# Sets up ADB
setupAdb(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupAdb
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
          _setupAdbUsage
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupAdb
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupAdb.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupAdb "$@"