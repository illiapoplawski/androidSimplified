#!/usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Installs the required packages for building Android on RedHat Distros
#/
#/  Public Functions:
#/
#/ Usage: $setupRedHatDistro [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   setupRedHatDistro
#/   setupRedHatDistro --help
#/


# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupRedHatDistro
#
# Installs the required packages for building Android on RedHat Distros
_setupRedHatDistro() {
  log -i "Installing Packages"
  if command -v dnf &>/dev/null; then
    # DNF is the better version of yum, use if available
    sudo dnf update -y
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y @development-tools android-tools automake bison bzip2 bzip2-libs ccache curl \
      dpkg-dev autoconf213 flex gawk gcc gcc-c++ git glibc-devel gperf glibc-static libstdc++-static \
      libX11-devel make mesa-libGL-devel ncurses-devel patch zlib-devel ncurses-devel.i686 \
      readline-devel.i686 zlib-devel.i686 libX11-devel.i686 mesa-libGL-devel.i686 glibc-devel.i686 \
      libstdc++.i686 libXrandr.i686 zip perl-Digest-SHA wget lzop openssl-devel java-1.8.0-openjdk-devel \
      ncurses-compat-libs schedtool libxml2-devel lz4-libs maven python python3 python3-mako python-mako \
      python-networkx squashfs-tools syslinux-devel zip clang ffmpeg pngcrush
  else
    # DNF not available, use YUM
    sudo yum -y update
    sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    rpm --import http://wiki.psychotic.ninja/RPM-GPG-KEY-psychotic
    rpm -ivh http://packages.psychotic.ninja/6/base/i386/RPMS/psychotic-release-1.0.0-1.el6.psychotic.noarch.rpm
    sudo yum -y --enablerepo=psychotic install schedtool
    sudo yum -y install epel-release yum-utils # https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
    sudo yum -y groupinstall "Development Tools" development
    sudo yum -y install android-tools automake bison bzip2 bzip2-libs ccache curl \
      dpkg-dev autoconf213 flex gawk gcc gcc-c++ git glibc-devel gperf glibc-static libstdc++-static \
      libX11-devel make mesa-libGL-devel ncurses-devel patch zlib-devel ncurses-devel.i686 \
      readline-devel.i686 zlib-devel.i686 libX11-devel.i686 mesa-libGL-devel.i686 glibc-devel.i686 \
      libstdc++.i686 libXrandr.i686 zip perl-Digest-SHA wget lzop openssl-devel java-1.8.0-openjdk-devel \
      libxml2-devel lz4-devel maven python python36 python-mako python-networkx squashfs-tools \
      syslinux-devel zip clang ffmpeg pngcrush
  fi

  "$SCRIPT_DIR"/installNinja.sh
  log -i "Packages installed"
}

# Show setup RedHat Distro usage
_setupRedHatDistroUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupRedHatDistro [args]
#
# Installs the required packages for building Android on RedHat Distros
setupRedHatDistro(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupRedHatDistro
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
          _setupRedHatDistroUsage
          exit 0
          ;;
        *)
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupRedHatDistro
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupRedHatDistro.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupRedHatDistro "$@"
