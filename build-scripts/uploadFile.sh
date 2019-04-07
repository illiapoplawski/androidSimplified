#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Uploads a file and its MD5 and changelog if available
#/
#/  Public Functions:
#/
#/ Usage: uploadFile [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory to move file to
#/   -f, --file <path>
#/                File to upload
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   uploadFile
#/   uploadFile -d <path/to/dir> -f <name>
#/   uploadFile --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
UPLOAD_LOG=$(dirname "$SCRIPT_DIR")/log/upload.log

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$SCRIPT_DIR"/setUploadDir.sh

# Usage: _uploadFile
#
# Upload a file
_uploadFile() {
  local file_dir
  local file_name

  if [[ ! -v UPLOAD_DIR ]]; then
    setUploadDir -d "$out_dir" || exit $?
  fi

  if [[ ! -v upload_file || -z $upload_file || "$upload_file" == " " ]]; then
    upload_file=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getFile -t "Select the file to upload" -o "$HOME")
  fi

  file_dir=$(dirname "$upload_file")
  file_name=$(basename "${upload_file%.*}")

  if [[ ! -f $upload_file ]]; then
    log -e "Unknown file to upload: $file_name"
    exit 1
  fi

  if [[ -v reset_log ]]; then
    log -i "Resetting upload log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$UPLOAD_LOG"
  fi

  log -i "Uploading: $file_name, to $UPLOAD_DIR"
  cp -v "$upload_file" "$UPLOAD_DIR" >> "$UPLOAD_LOG"
  if [[ -f "$file_dir"/"$file_name".md5 ]]; then
    cp -v "$file_dir"/"$file_name".md5 "$UPLOAD_DIR" >> "$UPLOAD_LOG"
  fi
  if [[ -f "$file_dir/$file_name.md5" ]]; then
    cp -v "$file_dir"/Changelog-"$file_name".md "$UPLOAD_DIR" >> "$UPLOAD_LOG"
  fi
  log -i "Upload complete"
}

# Show upload file usage
_uploadFileUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: uploadFile [arg]
#
# Uploads a file to a dir
uploadFile(){
  local upload_file
  local out_dir
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _uploadFile
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
          _uploadFileUsage
          exit 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              out_dir="$dir"
            else 
              log -w "No upload directory parameter specified"
            fi
          fi
          ;;
        -f|--file)
          local file="$2"
          shift # past argument
          if [[ "$file" != '-'* ]]; then
            shift # past value
            if [[ -n $file && "$file" != " " ]]; then
              upload_file="$file"
            else 
              log -w "No file parameter specified"
            fi
          fi
          ;;
        -r|--reset)
          shift # past argument
          reset_log=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _uploadFile
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./uploadFile.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && uploadFile "$@"
