#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up ccache
#/
#/  Public Functions:
#/
#/ Usage: setupCCache [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -a|--auto
#/                Auto set ccache to recommended settings
#/   -c, --ccache <true|false>
#/                Automatically set ccache without dialog
#/   -d|--directory <path/to/ccache/dir>
#/                Set ccache directory
#/
#/ EXAMPLES
#/   setsetupCCacheupNinja
#/   setupCCache -c true
#/   setupCCache -d <path/to/ccache/dir> -c false
#/   setupCCache -a
#/  

# Ensures script is only sourced once
if [[ ${SETUP_CCACHE_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SETUP_CCACHE_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SETUP_CCACHE_SCRIPT_NAME ]]  || readonly SETUP_CCACHE_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SETUP_CCACHE_SCRIPT_DIR ]]  || readonly SETUP_CCACHE_SCRIPT_DIR="$( cd "$( dirname "$SETUP_CCACHE_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SETUP_CCACHE_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setupCCache
#
# Sets up ccache
_setupCCache() {
  local ccache_dir_path

  if [[ -v auto_ccache ]]; then
    USE_CCACHE=1
    CCACHE_DIR="$HOME"/.ccache
  else
    if [[ ! -v USE_CCACHE || -z $USE_CCACHE || "$USE_CCACHE" == " " ]]; then
      if "$(dirname "$SETUP_CCACHE_SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Setup ccache" -d "Would you like to use ccache to compile the source code?"; then
        USE_CCACHE=1
      else
        USE_CCACHE=0
      fi
    fi

    if [[ $USE_CCACHE -eq 1 ]]; then
      log -i "Compiling with ccache"

      # Setup ccache directory
      if [[ ! -v CCACHE_DIR || -z $CCACHE_DIR || $CCACHE_DIR == " " ]]; then
        ccache_dir_path=$("$(dirname "$SETUP_CCACHE_SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your ccache base directory" -o "$HOME") || {
          log -w "ccache directory not specified.  Setting to default."
          ccache_dir_path="$HOME"
        }
        if [[ ! -d $ccache_dir_path ]]; then
          log -w "CCache directory: $ccache_dir_path does not exist.  Setting to home."
          ccache_dir_path="$HOME"
        fi
        CCACHE_DIR="$ccache_dir_path"/.ccache
        log -i "CCache dir set to: $CCACHE_DIR"
      else
        log -i "CCache base dir was already set to $CCACHE_DIR"
      fi
    else
      log -i "Not compiling with ccache"
    fi
  fi
  export USE_CCACHE
  export CCACHE_DIR
}

# Show setup ccache usage info
_setupCCacheUsage() {
  grep '^#/' "${SETUP_CCACHE_SCRIPT_DIR}/${SETUP_CCACHE_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupCCache [arg]
#
# Sets up ccache
setupCCache(){
  local auto_ccache
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _setupCCache
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
          _setupCCacheUsage
          return 0
          ;;
        -d|--directory) 
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              CCACHE_DIR="$dir/.ccache"
            else 
              log -w "No ccache directory parameter specified"
            fi
          fi
          ;;
        -c|--ccache) 
          local value="$2"
          shift # past argument
          if [[ "$value" != '-'* ]]; then
            shift # past value
            if [[ -n $value && "$value" != " " ]]; then
              if [[ "$value" = "true" ]]; then
                USE_CCACHE=1
              elif [[ "$value" = "false" ]]; then
                USE_CCACHE=0
              else
                log -e "Unknown arguments passed"; _setupCCacheUsage; return 128
              fi
            else
              log -w "Empty use ccache parameter"
            fi
          else
            log -w "No use ccache parameter specified"
          fi
          ;;
        -a|--auto) 
          shift
          auto_ccache=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupCCache
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setupCCache.sh\" instead."
  exit 1
fi