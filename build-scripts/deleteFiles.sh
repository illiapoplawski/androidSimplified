#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Deletes files matching a specific pattern
#/
#/  Public Functions:
#/
#/ Usage: deleteFiles [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory from which to delete files
#/   -p, --pattern <pat> [pat]
#/                File patterns to delete
#/   -k, --keep <int>
#/                Number of files to keep with similar name
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   deleteFiles
#/   deleteFiles -d <path> -p <pattern> [pattern] -k <int>
#/   deleteFiles --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
UPLOAD_LOG=$(dirname "$SCRIPT_DIR")/log/upload.log

mkdir -p "${UPLOAD_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _deleteFiles
#
# Deletes files
_deleteFiles() {
  if [[ ! -v file_dir || -z $file_dir || $file_dir == " " || ! -d $file_dir ]]; then
    if file_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Select the directory from which to delete files" -o "$HOME"); then
      log -i "File Directory set to $file_dir."
    else
      log -e "File Directory not specified"
      exit 1
    fi
  fi
  file_dir=${file_dir%/}

  if [[ ! -d $file_dir ]]; then
    log -e "File Directory: $file_dir does not exist."
    exit 1
  fi

  if [[ ! -v patterns || ${#patterns[@]} -eq 0 ]]; then
    local IFS=' '
    read -r -a patterns <<< "$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Delete Files" -d "Enter the file name patterns to delete\n(Space Delimited)")" || {
      log -e "No patterns specified"
      exit 1
    }
  fi

  if [[ ! -v patterns || ${#patterns[@]} -eq 0 ]]; then
    log -e "No patterns specified."
    exit 1
  fi

  if [[ ! -v keep_days || -z $keep_days || "$keep_days" == " " ]]; then
    keep_days=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Delete files" -d "Input the number of files to keep") || {
      log -e "Number of days not specified.  Cancelled by user"
      exit 1
    }
  fi

  if ! "$(dirname "$SCRIPT_DIR")"/utilities/mathFunctions.sh isInt "$keep_days"; then
    log -e "Invalid keep parameter"
    exit 1
  fi

  if [[ -v reset_log ]]; then
    log -i "Resetting upload log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$UPLOAD_LOG"
  fi
  
  log -i "Deleting old files from: $file_dir"
  for pattern in "${patterns[@]}"; do
    if [ -n "$(find "$file_dir" -maxdepth 1 -name "$pattern" -print)" ]; then
      find "$file_dir" -maxdepth 1 -name "$pattern" -type f  -printf '%T@ %p\n' | sort -nr | tail -n "+$(( keep_days + 1 ))" | cut -f 2- -d " " | xargs -i rm {} >> "$UPLOAD_LOG"
    fi
  done
  log -i "File deletion complete"
}

# Show delete files usage
_deleteFilesUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: deleteFiles [arg]
#
# Deletes files from a dir
deleteFiles() {
  local file_dir
  local patterns
  local keep_days
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _deleteFiles
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      if [[ "$action" != '-'* ]]; then
        shift
        continue
      fi
      case $action in
        -h|--help) 
          shift
          _deleteFilesUsage
          exit 0
          ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              file_dir="$dir"
            else 
              log -w "No file directory parameter specified"
            fi
          fi
          ;;
        -p|--pattern)
          local args
          shift # past argument
          args=("$@")
          if [[ ${#args[@]} -gt 0 ]]; then
            patterns=()
            for arg in "${args[@]}"; do
              if [[ "$arg" != '-'* ]]; then
                shift # past value
                if [[ -n $arg && "$arg" != " " ]]; then
                  patterns+=("$arg")
                fi
              else
                break
              fi
            done
          fi
          ;;
        -k|--keep)
          local keep=$2
          shift # past argument
          if [[ "$keep" != '-'* ]]; then
            shift # past value
            if [[ -n $keep && "$keep" != " " ]]; then
              keep_days="$keep"
            else
              log -e "Empty keep parameter"
              exit $?
            fi
          else
            log -w "No keep parameter specified"
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
    _deleteFiles
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./deleteFiles.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && deleteFiles "$@"
