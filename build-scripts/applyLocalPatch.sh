#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Applies a local patch to the specified repo
#/
#/  Public Functions:
#/
#/ Usage: $applyLocalPatch [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -t, --target <relative/path/to/target/dir>
#/                Target dir for patch (relative to Top Dir)
#/   -p, --patchdir <path/to/dir>
#/                Directory containing patch file
#/   -n, --patchname <patch filename>
#/                Patch file name
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   applyLocalPatch
#/   applyLocalPatch -d <path/to/root/dir> -t <relative/path/to/target/dir>
#/   applyLocalPatch -p <path/to/patch/dir> -n <patch filename>
#/   applyLocalPatch --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
REPOPICK_LOG=$(dirname "$SCRIPT_DIR")/log/repopick.log

mkdir -p "${REPOPICK_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _applyLocalPatch
#
# Apply a local patch file
_applyLocalPatch() {
  local patch_target
  local patch_file

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v patch_target_rel || -z $patch_target_rel || "$patch_target_rel" == " " ]]; then
    patch_target=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your patch file's target directory" -o "$BUILD_TOP_DIR") || {
      log -e "Local patch target dir not specified."
      exit 1
    }
    patch_target_rel=${patch_target#"$BUILD_TOP_DIR/"}
  else
    patch_target="$BUILD_TOP_DIR"/"$patch_target_rel"
  fi

  if [[ ! -d $patch_target ]]; then
    log -e "Patch target directory: ${patch_target_rel} does not exist."
    exit 1
  fi

  patch_dir=${patch_dir%/}
  if [[ ! -v patch_dir || -z $patch_dir || "$patch_dir" == " " || ! -d $patch_dir || 
        ! -v patch_name_no_path || -z $patch_name_no_path || "$patch_name_no_path" == " " ]]; then
    patch_file=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getFile -t "Choose your local patch file" -o "$BUILD_TOP_DIR") || {
      log -e "Patch file not specified."
      exit $?
    }
    patch_name_no_path=${patch_file##*/}
    #patch_dir=$(dirname "$patch_file")
  else
    patch_file="$patch_dir"/"$patch_name_no_path"
  fi

  if [[ ! -f $patch_file ]]; then
    log -e "Patchfile ${patch_name_no_path} does not exist."
    exit 1
  fi
  
  if [[ -v reset_log ]]; then
    log -i "Resetting repopick log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$REPOPICK_LOG"
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR"

  # Navigate to target
  pushd "$patch_target" &>/dev/null || exit $?
  log -i "Applying local patch: ${patch_name_no_path}"

  # Create auto branch
  repo start auto
  
  local log_out
  # Apply patch
  if log_out=$(git am "$patch_file" | tee -a "$REPOPICK_LOG"); then
    if echo "$log_out" | grep -Eqwi 'error'; then
      log -e "Failed to apply github checkout due to repopick errors.  Please check repopick.log for details"
      exit 1
    else
      log -i "Successfully applied local patch to: $patch_target_rel"
    fi
  else
    log -e "Failed to apply local patch to: $patch_target_rel"
    exit 1
  fi
  popd &>/dev/null || exit $?
}

# Show apply local patch usage
_applyLocalPatchUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: applyLocalPatch [arg]
#
# Apply a local patch file
applyLocalPatch(){
  local patch_dir
  local patch_name_no_path
  local patch_target_rel
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _applyLocalPatch
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
          _applyLocalPatchUsage
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
        -p|--patchdir)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              patch_dir="$dir"
            else
              log -w "Invalid patch directory passed"
            fi
          else
            log -w "No patch directory parameter specified"
          fi
          ;;
        -n|--patchname)
          local name="$2"
          shift # past argument
          if [[ "$name" != '-'* ]]; then
            shift # past value
            if [[ -n $name && "$name" != " " ]]; then
              patch_name_no_path="$name"
            else
              log -w "Empty patch file name parameter"
            fi
          else
            log -w "No patch file name parameter specified"
          fi
          ;;
        -t|--target)
          local target="$2"
          shift # past argument
          if [[ "$target" != '-'* ]]; then
            shift # past value
            if [[ -n $target && "$target" != " " ]]; then
              patch_target_rel="$target"
            else
              log -w "Empty target relative path parameter"
            fi
          else
            log -w "No target relative path parameter specified"
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
    _applyLocalPatch
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./applyLocalPatch.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && applyLocalPatch "$@"
