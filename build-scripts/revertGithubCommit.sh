#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Reverts a specific commit in a repo
#/
#/  Public Functions:
#/
#/ Usage: $revertGithubCommit [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -t, --target <relative/path/to/target/dir>
#/                Target dir for revert (relative to Top Dir)
#/   -c, --hash <hash>
#/                HASH of commit
#/
#/ EXAMPLES
#/   revertGithubCommit
#/   revertGithubCommit -d <path/to/root/dir> -t <relative/path/to/target/dir> -c <hash>
#/   revertGithubCommit --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
REPOPICK_LOG="$(dirname "$SCRIPT_DIR")"/log/repopick.log

mkdir -p "${REPOPICK_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _revertGithubCommit
#
# Revert a github commit
_revertGithubCommit() {
  local revert_target

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v revert_target_rel || -z $revert_target_rel || "$revert_target_rel" == " " ]]; then
    revert_target=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your revert commit's target directory" -o "$BUILD_TOP_DIR") || {
      log -e "Revert target dir not specified."
      exit 1
    }
    revert_target_rel=${revert_target#"$BUILD_TOP_DIR/"}
  else
    revert_target="$BUILD_TOP_DIR"/"$revert_target_rel"
  fi

  if [[ ! -d $revert_target ]]; then
    log -e "Revert target directory: $revert_target_rel does not exist."
    exit 1
  fi

  if [[ ! -v commit_hash || -z $commit_hash || "$commit_hash" == " " ]]; then
    commit_hash=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Revert Github Commit" -d "Input HASH for commit to revert") || {
      log -e "Revert commit hash not specified."
      exit 1
    }
  fi

  if [[ -v reset_log ]]; then
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$REPOPICK_LOG"
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR"

  # Navigate to target
  pushd "$revert_target" &>/dev/null || exit
  log -i "Reverting commit id $commit_hash"

  # Create auto branch
  repo start auto

  local parents=$(( $(git log -1 "$commit_hash" |& grep "Merge: " | wc -w) - 1 ))

  local log_out
  if [[ $parents -gt 0 ]]; then
    log_out=$(git revert --no-edit -m $parents "$commit_hash" | tee -a "$REPOPICK_LOG")
  else
    log_out=$(git revert --no-edit "$commit_hash" | tee -a "$REPOPICK_LOG")
  fi
  local ret=$?
  if [[ $ret -eq 0 ]]; then 
    if echo "$log_out" | grep -Eqwi 'error'; then
      log -e "Failed to revert commit due to repopick errors.  Please check repopick.log for details"
      exit 1
    else
      log -i "Successfully reverted commit from: $revert_target_rel"
    fi
  else
    log -e "Failed to revert commit from: $revert_target_rel"
    exit $ret
  fi
  popd &>/dev/null || exit $?
}

# Show revert github commit usage
_revertGithubCommitUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: revertGithubCommit
#
# Revert a github commit
revertGithubCommit(){
  local revert_target_rel
  local commit_hash
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _revertGithubCommit
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
          _revertGithubCommitUsage
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
        -t|--target)
          local target=$2
          shift # past argument
          if [[ "$target" != '-'* ]]; then
            shift # past value
            if [[ -n $target && "$target" != " " ]]; then
              revert_target_rel="$target"
            else
              log -w "Empty revert target directory parameter"
            fi
          else
            log -w "No revert target directory parameter specified"
          fi
          ;;
        -c|--hash)
          local hash=$2
          shift # past argument
          if [[ "$hash" != '-'* ]]; then
            shift # past value
            if [[ -n $hash && "$hash" != " " ]]; then
              commit_hash="$hash"
            else
              log -w "Empty commit hash parameter"
            fi
          else
            log -w "No commit hash parameter specified"
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
    _revertGithubCommit
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./revertGithubCommit.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && revertGithubCommit "$@"
