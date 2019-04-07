#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the ccache size
#/
#/  Public Functions:
#/
#/ Usage: setCCacheSize [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -s|--size <size>
#/                Size of CCache in GB
#/
#/ EXAMPLES
#/   setCCacheSize
#/   setCCacheSize -d <path/to/root/dir>
#/   setCCacheSize --size <size>
#/   setCCacheSize -s <size> -d <path/to/root/dir>
#/   setCCacheSize --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _setCCacheSize
#
# Sets the ccache size
_setCCacheSize() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v ccache_size_gb || -z $ccache_size_gb || "$ccache_size_gb" == " " ]]; then
    local prev_size
    prev_size=$(ccache -s |& grep "max cache size" | awk '{print $4}')
    ccache_size_gb=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Set ccache size" -d "Input size for ccache in GB" -i "$prev_size") || {
      log -e "Cache size not specified."
      exit 1
    }
  fi

  if ! "$(dirname "$SCRIPT_DIR")"/utilities/mathFunctions.sh isNumber "$ccache_size_gb"; then
    log -e "ccache size argument invalid."
    exit 1
  fi

  "$BUILD_TOP_DIR"/prebuilts/misc/linux-x86/ccache/ccache -M "${ccache_size_gb}"GB || exit $?
}

# Show clear ccache usage
_setCCacheSizeUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setCCacheSize [arg]
#
# Sets the ccache size
setCCacheSize(){
  local ccache_size_gb

  local action
  if [[ ${#} -eq 0 ]]; then
    _setCCacheSize
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
          _setCCacheSizeUsage
          exit 0
         ;;
        -d|--directory) 
          local dir="$2"
          shift # past argument
          if [[ -n "$dir" && "$dir" != " " && "$dir" != '-'* ]]; then
            if [[ ! -d "$dir" ]]; then
              log -w "Invalid base directory passed"
            else
              BUILD_TOP_DIR="$dir"
            fi
            shift # past value
          else
            log -w "No base directory parameter specified"
          fi
          ;;
        -s|--size) 
          local size="$2"
          shift # past argument
          if [[ "$size" != '-'* ]]; then
            shift # past value
            if [[ -n $size && "$size" != " " ]]; then
              ccache_size_gb=$size
            else
              log -w "Empty ccache size parameter"
            fi
          else
            log -w "No ccache size parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setCCacheSize
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./clearCCache.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setCCacheSize "$@"
