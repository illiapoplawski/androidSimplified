#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Archives a file and its MD5 and changelog if available
#/
#/  Public Functions:
#/
#/ Usage: archiveFile [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory to move file to
#/   -f, --file <path>
#/                File to archive
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   archiveFile
#/   archiveFile -d <path/to/upload/dir> -f <path/to/file>
#/   archiveFile --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
UPLOAD_LOG=$(dirname "$SCRIPT_DIR")/log/upload.log

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$SCRIPT_DIR"/setUploadDir.sh

# Usage: _archiveFile
#
# Archives a file
_archiveFile() {
  local file_dir
  local file_name

  if [[ ! -v archive_dir || -z $archive_dir || "$archive_dir" == " " ]]; then
    archive_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose the directory to archive the file to" -o "$HOME") || {
      log -e "Archive directory not specified."
      return 1
    }
  fi

  if [[ ! -d $archive_dir ]]; then
    log -e "Archive directory: $archive_dir does not exist."
    return 1
  fi

  archive_dir=${archive_dir%/}

  if [[ ! -v archive_file || -z $archive_file || "$archive_file" == " " ]]; then
    archive_file=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getFile -t "Select the file to archive" -o "$HOME")
  fi

  for f in $archive_file; do
    [ -e "$f" ] || {
      log -e "Unknown file to archive: $f"
      exit 1
    }
  done

  if [[ -v reset_log ]]; then
    log -i "Resetting upload log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$UPLOAD_LOG"
  fi
  
  file_dir=$(dirname "$archive_file")
  file_name=()
  IFS=" " read -r -a file_name <<< "$(basename "${archive_file%.*}")"

  pushd "$file_dir" &>/dev/null || exit $?
  local zips
  zips=( ${file_name[@]/%/.zip} )
  for f in "${zips[@]}"; do
    mv -v "$f" "$archive_dir" >> "$UPLOAD_LOG"
  done
  
  local md5
  md5=( ${file_name[@]/%/.md5} )
  for f in "${md5[@]}"; do
    mv -v "$f" "$archive_dir" >> "$UPLOAD_LOG"
  done

  local md
  md=( ${file_name[@]/%/.md} )
  for f in "${md[@]}"; do
    mv -v "$f" "$archive_dir" >> "$UPLOAD_LOG"
  done
  popd &>/dev/null || exit $?
}

# Show archive file usage
_archiveFileUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: archiveFile [arg]
#
# Archives a file to a dir
archiveFile(){
  local archive_file
  local archive_dir
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _archiveFile
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
          _archiveFileUsage
          exit 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              archive_dir="$dir"
            else 
              log -w "No archive directory parameter specified"
            fi
          fi
          ;;
        -f|--file)
          local file="$2"
          shift # past argument
          if [[ "$file" != '-'* ]]; then
            shift # past value
            if [[ -n $file && "$file" != " " ]]; then
              archive_file="$file"
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
    _archiveFile
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./archiveFile.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && archiveFile "$@"
