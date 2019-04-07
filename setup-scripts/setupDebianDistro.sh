#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the required packages for building Android on Debian Distros
#/
#/  Public Functions:
#/
#/ Usage: $setupDebianDistro [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupDebianDistro
#/   setupDebianDistro --help
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupDebianDistro
#
# Installs the required packages for building Android on Debian Distros
_setupDebianDistro() {
  local curOS
  curOS=$("$SCRIPT_DIR"/determineOS.sh)
  local tmp=${curOS%%, ver: *}
  local name=${tmp##os: }
  local ver=${curOS##* ver: }

  log -i "Updating package repositories"

  if [[ ("$name" == "Ubuntu" || "$name" == "ubuntu") && "$ver" == "14"* ]]; then
    # Ubuntu 14 does not include openjdk in its repositories so need to add a ppa for it.
    # Java is already included in aosp when building for pie but is required for older versions of android
    sudo add-apt-repository -y ppa:openjdk-r/ppa
  fi
  
  sudo apt update -qq -o=Dpkg::Use-Pty=0
  sudo apt upgrade -y -qq -o=Dpkg::Use-Pty=0

  log -i "Installing Packages"
  sudo apt install -y -qq -o=Dpkg::Use-Pty=0 git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib \
    g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev \
    libxml2-utils xsltproc unzip python-networkx autoconf automake axel bc clang cmake expat \
    g++ figlet gawk gcc htop imagemagick lib32z1-dev libc6-dev autopoint \
    libcap-dev libcloog-isl-dev libexpat1-dev libgmp-dev liblz4-* liblzma* libmpc-dev libmpfr-dev libncurses5-dev \
    libsdl1.2-dev libssl-dev libtool libxml2 lzma* lzop maven ncftp ncurses-dev openjdk-8-jdk openjdk-8-jre \
    patch pkg-config pngcrush pngquant python python-all-dev re2c schedtool squashfs-tools subversion texinfo w3m \
    android-tools-adb android-tools-fastboot
  
  sudo apt purge -y -qq -o=Dpkg::Use-Pty=0 openjdk-11-* &>/dev/null

  "$SCRIPT_DIR"/setupAdb.sh
  "$SCRIPT_DIR"/installMake.sh
  "$SCRIPT_DIR"/installAutoMake.sh
  "$SCRIPT_DIR"/installGetText.sh
  "$SCRIPT_DIR"/installFlex.sh
  "$SCRIPT_DIR"/installCCache.sh
  "$SCRIPT_DIR"/installNinja.sh
  "$SCRIPT_DIR"/installRepo.sh
  log -i "Packages installed"
}

# Show setup Debian Distro usage
_setupDebianDistroUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupDebianDistro [args]
#
# Installs the required packages for building Android on Debian Distros
setupDebianDistro(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupDebianDistro
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
          _setupDebianDistroUsage
          exit 0
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupDebianDistro
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupDebianDistro.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupDebianDistro "$@"