#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Syncs a repo
#/
#/  Public Functions:
#/
#/ Usage: syncRepo [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Specify Top Dir for Android source
#/   -a, --auto
#/                Automatically sync repo without confirmation
#/
#/ EXAMPLES
#/   syncRepo
#/   syncRepo -d <path/to/dir> -a
#/   syncRepo --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
SYNC_LOG="$(dirname "$SCRIPT_DIR")"/log/sync.log

mkdir -p "${SYNC_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh

# Usage: _syncRepo
#
# Syncs a repo
_syncRepo() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$SYNC_LOG"

  if [[ ! -v autoSync ]]; then
    "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Sync Repo" -d "Would you like to sync the repository before building?" || {
      log -w "Not syncing repo"
      exit 0
    }
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR" || exit $?

  log -i "Sync repository"
  pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
  if repo sync -c -f --force-sync --no-tag --no-clone-bundle -j"$(nproc --all)" --optimized-fetch --prune >> "$SYNC_LOG"; then
    if grep -Eqwi 'fatal|error' "$SYNC_LOG"; then
      log -e "error: Exit sync due to fetch errors, please check sync.log and correct the issue"
      exit 1
    else
      log -i "Repo sync completed without errors"
    fi
  else
    log -e "Repo sync failed!"
    exit 1
  fi
  popd &>/dev/null || exit $?
}

# Show sync repo usage
_syncRepoUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: syncRepo [arg]
#
# Syncs a repo
syncRepo(){
  local autoSync

  local action
  if [[ ${#} -eq 0 ]]; then
    _syncRepo
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
          _syncRepoUsage
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
        -a|--auto) 
          shift
          autoSync=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _syncRepo
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./syncRepo.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && syncRepo "$@"
