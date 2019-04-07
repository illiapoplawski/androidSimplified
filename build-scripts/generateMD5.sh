#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Generates an MD5 checksum for a file
#/
#/  Public Functions:
#/
#/ Usage: generateMD5 [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -f, --file <path>
#/                File for which to generate MD5 checksum
#/
#/ EXAMPLES
#/   generateMD5
#/   generateMD5 -f <path/to/file>
#/   generateMD5 --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh

# Usage: _generateMD5
#
# Generates an MD5 checksum for the specified file
_generateMD5(){
  local file_dir
  local file_name

  if [[ ! -v file_path || -z $file_path || "$file_path" == " " || ! -f $file_path ]]; then
    file_path=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getFile -t "Select the file for which to generate an MD5 checksum" -o "$HOME") || {
      log -e "File path not specified. Not generating md5."
      exit 0
    }
  fi
  file_dir=$(dirname "${file_path}")
  file_name=$(basename "${file_path%.*}")
  log -i "Generating MD5 for $file_name"
  echo "$(md5sum "$file_path" | awk '{ print $1 }') $file_name" > "$file_dir"/"$file_name".md5
  log -i "MD5 Generated"
}

# Show generate MD5 checksum usage
_generateMD5Usage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: generateMD5 [arg]
#
# Generates an MD5 checksum for the specified file
generateMD5(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _generateMD5
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
          _generateMD5Usage
          exit 0
         ;;
        -f|--file)
          local file="$2"
          shift # past argument
          if [[ "$file" != '-'* ]]; then
            shift # past value
            if [[ -n $file && "$file" != " " ]]; then
              file_path="$file"
            else 
              log -w "No file parameter specified"
            fi
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _generateMD5
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./generateMD5.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && generateMD5 "$@"
