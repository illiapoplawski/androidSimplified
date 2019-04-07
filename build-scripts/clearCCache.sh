#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Clears ccache
#/
#/  Public Functions:
#/
#/ Usage: clearCCache [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -c, --clear
#/                Automatically clear CCache
#/
#/ EXAMPLES
#/   clearCCache
#/   clearCCache -d <path/to/root/dir>
#/   clearCCache --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _clearCCache
#
# Clears the CCache
_clearCCache() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ -v clear_ccache ]]; then
    "$BUILD_TOP_DIR"/prebuilts/misc/darwin-x86/ccache/ccache -C
  else
    local msg
    msg="Would you like to clear your ccache?\n\nThis should only be done in extreme situation where builds are failing to build and no other solution works"
    if "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Clear ccache" -d "$msg" -i "no"; then
      log -i "Clearing ccache"
      "$BUILD_TOP_DIR"/prebuilts/misc/linux-x86/ccache/ccache -C
    else
      log -i "Not clearing ccache"
    fi
  fi
}

# Show clear ccache usage
_clearCCacheUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: clearCCache [arg]
#
# Clears the ccache
clearCCache(){
  local clear_ccache

  local action
  if [[ ${#} -eq 0 ]]; then
    _clearCCache
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
          _clearCCacheUsage
          exit 0
         ;;
        -d|--directory) 
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              BUILD_TOP_DIR="$dir"
            else 
              log -w "No base directory parameter specified"
            fi
          fi
          ;;
        -c|--clear) 
          shift
          clear_ccache=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _clearCCache
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./clearCCache.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && clearCCache "$@"
