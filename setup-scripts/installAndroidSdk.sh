#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the Android SDK and the latest packages
#/
#/  Public Functions:
#/
#/ Usage: $installAndroidSdk [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -a, --auto
#/                Automatically installs the latest Sdk packages
#/
#/ EXAMPLES
#/   installAndroidSdk
#/   installAndroidSdk --help
#/   installAndroidSdk -a
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _installAndroidSdk
#
# Installs the Android Sdk and latest packages
_installAndroidSdk() {
  if [[ ! -v ANDROID_HOME ]]; then
    # export for local shell
    ANDROID_HOME="$HOME"/Android/Sdk
    # save for permanent use
    if ! grep -qxF "export ANDROID_HOME=$ANDROID_HOME" "$HOME"/.bashrc; then
      printf "\nexport ANDROID_HOME=%s" "$ANDROID_HOME" >> "$HOME"/.bashrc
      . "$HOME"/.bashrc
      log -i "Added ANDROID_HOME environment variable"
    fi
  fi
  
  local isLatest
  isLatest=$("$ANDROID_HOME"/tools/bin/sdkmanager --update | grep -c "tools")
  if [[ $isLatest -ne 0 ]]; then
    log -i "Installing the Android Sdk Tools"
    curl -s https://developer.android.com/studio/index.html#command-tools | grep 'sdk-tools-linux' | cut -d '"' -f 2 | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" | wget -O /tmp/android-sdk-tools.zip --show-progress -qci - || {
        echo "Failed to download Android Sdk Tools"
        exit 1
    }

    mkdir -p ~/Android/Sdk && unzip -qo /tmp/android-sdk-tools.zip -d "$_" || {
        echo "Failed to install Android Sdk Tools"
        exit 1
    }
    rm -f /tmp/android-sdk-tools.zip
    
    log -i "Android Sdk Tools installed"
  else
    log -i "Latest Sdk Tools already installed"
  fi

  local updates
  updates=$("$ANDROID_HOME"/tools/bin/sdkmanager --update | grep -cvE "\[.*\\.\\.\\.")
  if [[ $updates -gt 0 ]]; then
    if [[ ! -v auto_install ]]; then
      "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Install Android Sdk" -d "Would you like to install the latest packages for the Android Sdk?" || {
        log -i "Not installing packages"
        exit 0
      }
    fi
    log -i "Installing Android Sdk Packages"

    if [ ! -f ~/.android/repositories.cfg ] ; then
        touch ~/.android/repositories.cfg
    fi
    echo "home:$ANDROID_HOME:"
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses

    # get list of all latest packages and remove blank spaces and all other data except for package and version numbers,
    # then only list available packages and not the installed ones to remove duplicates
    package_list="$("$ANDROID_HOME"/tools/bin/sdkmanager --list | tr -d "[:blank:]" | grep -Eo '^[^|]+' | sed -n '/^AvailablePackages:$/,$p')"

    packages=('build-tools' 'cmake' 'emulator' 'ndk-bundle' 'extras;android;gapid;3' 'extras;android;m2repository' \
    'extras;google;auto' 'extras;google;google_play_services' 'extras;google;instantapps' 'extras;google;m2repository' \
    'extras;google;market_apk_expansion' 'extras;google;market_licensing' 'extras;google;simulators' \
    'extras;google;webdriver' 'lldb' 'platform-tools' 'platforms' 'tools')

    versioned_packages=()
    for package in "${packages[@]}"; do
      # get all package versions for package, remove release candidates (-rc[number] or -[letter] eg), sort then grab latest
      versioned_packages+=("$(echo "$package_list" | grep -e "^$package"  | grep -vE "\-rc[0-9]$" | grep -vE "\-[a-zA-Z]$" | sort -V | tail -n 1)")
    done
    "$ANDROID_HOME"/tools/bin/sdkmanager "${versioned_packages[@]}"
    log -i "Android Sdk packages installed"
  else
    log -i "You already have all the latest packages"
  fi
  
}

# Show install android sdk usage
_installAndroidSdkUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: installAndroidSdk [args]
#
# Installs the Android Sdk and latest packages
installAndroidSdk(){
  local auto_install

  local action
  if [[ ${#} -eq 0 ]]; then
    _installAndroidSdk
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
          _installAndroidSdkUsage
          exit 0
          ;;
        -a|--auto)
          shift
          auto_install=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _installAndroidSdk
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./installAndroidSdk.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && installAndroidSdk "$@"