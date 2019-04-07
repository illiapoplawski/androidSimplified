#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: setupRomRepo [OPTIONS]... [ARGUMENTS]...
#/ 
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -a, --account <Github account>
#/                Github account name
#/   -m, --manifest <manifest repo_name>
#/                Github manifest repo name
#/   -b, --branch <ref>
#/                Branch to initialize repo to
#/   --sync [true|false]
#/                Sync repo
#/
#/ EXAMPLES
#/   setupRomRepo -h
#/   setupRomRepo -d <path/to/root/dir> -a <GithubAcc> -m <manifest_repo_name> -b <branch> --sync
#/ 

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh
. "$SCRIPT_DIR"/utilities/setTopDir.sh
. "$SCRIPT_DIR"/utilities/verifyPythonVenv.sh

# Usage: _setupRomRepo
#
# Sets up a rom repo for building
_setupRomRepo() {
  if [[ ! -v top_dir ]]; then
    log -e "Build top directory must be specified"
    exit 1
  fi

  # Set build top dir
  setTopDir -d "$top_dir" || exit $?

  # Enable Python 2.7 virtual environment
  verifyPythonVenv || exit $?

  # Init repo
  "$SCRIPT_DIR"/setup-scripts/initRomRepo.sh -d "$BUILD_TOP_DIR" -a "$account_name" -m "$manifest_name" -b "$branch" || exit $?

  if [[ "$sync_repo" == "true" ]]; then
    # Sync repo
    "$SCRIPT_DIR"/build-scripts/syncRepo.sh --auto || exit $?
  fi
}

# Show setup rom repo usage
_setupRomRepoUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupRomRepo [args]
#
# Sets up a rom repo for building
setupRomRepo(){
  local top_dir
  local manifest_name="android_manifest"
  local account_name="StatixOS"
  local branch="9"
  local sync_repo="true"
    
  local action
  while [[ $# -gt 0 ]]; do
      action="$1"
      if [[ "$action" != '-'* ]]; then
        shift
        continue
      fi
      case $action in
        -h|--help)
          shift
          _setupRomRepoUsage
          exit 0
         ;;
        -d|--directory)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              top_dir="$dir"
            else 
              log -w "No base directory parameter specified"
            fi
          fi
          ;;
        -m|--manifest)
          local man=$2
          shift # past argument
          if [[ "$man" != '-'* ]]; then
            shift # past value
            if [[ -n $man && "$man" != " " ]]; then
              manifest_name="$man"
            else
              log -w "Empty manifest name parameter"
            fi
          else
            log -w "No manifest name parameter specified"
          fi
          ;;
        -a|--account)
          local acc=$2
          shift # past argument
          if [[ "$acc" != '-'* ]]; then
            shift # past value
            if [[ -n $acc && "$acc" != " " ]]; then
              account_name="$acc"
            else
              log -w "Empty account name parameter"
            fi
          else
            log -w "No account name parameter specified"
          fi
          ;;
        -b|--branch)
          local branch=$2
          shift # past argument
          if [[ "$branch" != '-'* ]]; then
            shift # past value
            if [[ -n $branch && "$branch" != " " ]]; then
              branch="$branch"
            else
              log -w "Empty branch parameter"
            fi
          else
            log -w "No branch parameter specified"
          fi
          ;;
        --sync) 
          local val="$2"
          shift # past argument
          if [[ "$val" != '-'* ]]; then
            sync_repo="$val"
            shift # past value
          else
            sync_repo="true"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
  _setupRomRepo
}

err_report() {
    local lineNo=$1
    local msg=$2
    echo "Error on line $lineNo: $msg"
    exit 1
}

trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./setupRomRepo.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && setupRomRepo "$@"
