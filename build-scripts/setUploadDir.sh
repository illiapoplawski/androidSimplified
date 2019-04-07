#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the build upload directory
#/
#/  Public Functions:
#/
#/ Usage: setUploadDir [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Upload Dir for built ROM
#/
#/ EXAMPLES
#/   setUploadDir
#/   setUploadDir -d <path>
#/   setUploadDir --help
#/

# Ensures script is only sourced once
if [[ ${SET_UPLOAD_DIR_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_UPLOAD_DIR_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_UPLOAD_DIR_SCRIPT_NAME ]]  || readonly SET_UPLOAD_DIR_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_UPLOAD_DIR_SCRIPT_DIR ]]  || readonly SET_UPLOAD_DIR_SCRIPT_DIR="$( cd "$( dirname "$SET_UPLOAD_DIR_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_UPLOAD_DIR_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setUploadDir
#
# Sets the build upload dir
_setUploadDir() {
  if [[ ( ! -v UPLOAD_DIR || -z $UPLOAD_DIR || "$UPLOAD_DIR" == " " ) &&
        ( ! -v upload_dir || -z $upload_dir || "$upload_dir" == " " ) ]]; then
    upload_dir=$("$(dirname "$SET_UPLOAD_DIR_SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose the directory to upload the file to" -o "$HOME") || {
      log -e "Upload directory not specified."
      return 1
    }
  fi

  if [[ ! -d $upload_dir ]]; then
    log -e "Upload directory: $upload_dir does not exist."
    return 1
  fi
  upload_dir=${upload_dir%/}
  export UPLOAD_DIR="$upload_dir"
}

# Show set build upload dir usage
_setUploadDirUsage() {
  grep '^#/' "${SET_TOPSET_UPLOAD_DIR_SCRIPT_DIR_DIR_SCRIPT_DIR}/${SET_UPLOAD_DIR_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setUploadDir [arg]
#
# Sets the build upload dir
setUploadDir(){
  local upload_dir

  local action
  if [[ ${#} -eq 0 ]]; then
    _setUploadDir
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help) 
          shift
          _setUploadDirUsage
          return 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ $dir != '-'* ]]; then
            shift # past value
            if [[ -n $dir ]]; then
              upload_dir="$dir"
            else 
              log -w "No upload directory parameter specified"
            fi
          fi
          ;;
        *) log -e "Unknown arguments passed:$action:"; _setUploadDirUsage; return 128 ;;
      esac
    done
    _setUploadDir
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setUploadDir.sh\" instead."
  exit 1
fi