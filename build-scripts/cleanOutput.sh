#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Cleans the out folder
#/
#/  Public Functions:
#/
#/ Usage: cleanOutput [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory to save changelog to
#/   -c, --clean <clean type>
#/                Clean types ( clean | installclean | none )
#/
#/ EXAMPLES
#/   cleanOutput
#/   cleanOutput -d <path/to/dir> -c <clean type>
#/   cleanOutput --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

build_types=('clean' 'installclean' 'none')

# Usage: cleanOutput
#
# Cleans the out folder
_cleanOutput() {
  local clean_opt=('clean' 'Full wipe of out directory')
  local install_clean_opt=('installclean' 'Partial wipe of out directory')
  local install_dirty_opt=('none' 'Dont'\''t wipe anything from out directory')

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v clean_type || -z $clean_type || "$clean_type" == " " ]]; then
    clean_type=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getOption -t "Clean output" -i "Choose your clean type" -o "${clean_opt[@]}" "${install_clean_opt[@]}" "${install_dirty_opt[@]}" ) || {
      log -e "Clean type not specified."
      exit 1
    }
  fi
  
  if ! "$(dirname "$SCRIPT_DIR")"/utilities/arrayFunctions.sh contains -a "${build_types[@]}" -v "$clean_type"; then
    log -e "Invalid clean type passed"
    exit 1
  fi

  unset IFS
  pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
  # Clean types
  case "$clean_type" in
    clean)
      log -i "Running \"make clean\" on output directory."
      if make clean; then
        log -i "Clean successful"
      else
        log -w "Output directory not cleaned successfully"
        exit 1
      fi
      ;;
    installclean)
      log -i "Running \"make installclean\" on output directory."
      if make installclean; then
        log -i "Clean successful"
      else
        log -w "Output directory not cleaned successfully"
        exit 1
      fi
      ;;
    none)
      log -w "Not wiping anything from output directory."
      ;;
    *) log -e "Unknown clean type"; exit 128; ;;
  esac
  popd &>/dev/null || exit $?
}

# Show clean output usage
_cleanOutputUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: cleanOutput [arg]
#
# Cleans the out folder
cleanOutput(){
  local clean_type
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _cleanOutput
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
          _cleanOutputUsage
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
        -c|--clean)
          local clean=$2
          shift # past argument
          if [[ "$clean" != '-'* ]]; then
            shift # past value
            if [[ -n $clean && "$clean" != " " ]]; then
              clean_type="$clean"
            else
              log -e "Empty clean type parameter"
              exit $?
            fi
          else
            log -w "No clean type parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _cleanOutput
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./cleanOutput.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && cleanOutput "$@"
