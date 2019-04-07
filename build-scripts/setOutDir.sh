#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the output files directory
#/
#/  Public Functions:
#/
#/ Usage: setOutDir [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -o, --outdir <path/to/dir>
#/                Specify Output dir for Android build files
#/
#/ EXAMPLES
#/   setOutDir
#/   setOutDir -t <build type>
#/   setOutDir --help
#/

# Ensures script is only sourced once
if [[ ${SET_OUT_DIR_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_OUT_DIR_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_OUT_DIR_SCRIPT_NAME ]]  || readonly SET_OUT_DIR_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_OUT_DIR_SCRIPT_DIR ]]  || readonly SET_OUT_DIR_SCRIPT_DIR="$( cd "$( dirname "$SET_OUT_DIR_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_OUT_DIR_SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SET_OUT_DIR_SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _setOutDir
#
# Sets the output directory
_setOutDir() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v out_dir || -z $out_dir || "$out_dir" == " " || ! -d $out_dir ]]; then
    if out_dir=$("$(dirname "$SET_OUT_DIR_SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your build output directory" -o "$BUILD_TOP_DIR"); then
      log -i "Build Out Directory set to $out_dir."
    else
      log -e "Build Out Directory not specified"
      return 1
    fi
  fi

  if [[ ! -d $out_dir ]]; then
    log -e "Output directory: $out_dir does not exist."
    return 1
  fi

  out_dir=${out_dir%/}
  
  if [[ ! $out_dir -ef $BUILD_TOP_DIR ]]; then
    export OUT_DIR_COMMON_BASE=$out_dir
  fi
}

# Show set out dir usage
_setOutDirUsage() {
  grep '^#/' "${SET_OUT_DIR_SCRIPT_DIR}/${SET_OUT_DIR_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setOutDir [arg]
#
# Sets the output directory
setOutDir(){
  local out_dir

  local action
  if [[ ${#} -eq 0 ]]; then
    _setOutDir
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help) 
          shift
          _setOutDirUsage
          return 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ -n "$dir" && "$dir" != " " && "$dir" != '-'* ]]; then
            if [[ ! -d "$dir" ]]; then
              log -w "Invalid directory passed"
            else
              BUILD_TOP_DIR="$dir"
            fi
            shift # past value
          else
            log -w "No base directory parameter specified"
          fi
          ;;
        -o|--outdir)
          local dir="$2"
          shift # past argument
          if [[ -n "$dir" && "$dir" != " " && "$dir" != '-'* ]]; then
            if [[ ! -d "$dir" ]]; then
              log -w "Invalid directory passed"
            else
              out_dir=$dir
            fi
            shift # past value
          else
            log -w "No output directory parameter specified"
          fi
          ;;
        *) log -e "Unknown arguments passed"; _setOutDirUsage; return 128 ;;
      esac
    done
    _setOutDir
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setOutDir.sh\" instead."
  exit 1
fi