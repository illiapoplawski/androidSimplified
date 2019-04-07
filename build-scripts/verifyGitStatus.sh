#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Verifies the git status of all projects in a repo
#/
#/  Public Functions:
#/
#/ Usage: verifyGitStatus [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Specify Top Dir for Android source
#/   -p, --project <path>
#/                Relative path to project dir from source top
#/   --all
#/                Verifies all projects
#/
#/ EXAMPLES
#/   verifyGitStatus
#/   verifyGitStatus -d <path/to/dir> -p <path>
#/   verifyGitStatus -d <path/to/dir> --all
#/   verifyGitStatus --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
GIT_STATUS_LOG="$(dirname "$SCRIPT_DIR")"/log/git_status.log

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _verifyGitStatus
#
# Verifies the git status of all projects in repo
_verifyGitStatus() {
  local status_out

  if [[ ! -v auto_verify ]]; then
    "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Verify Git Status" -d "Would you like to verify git status before building?" -i "yes" || {
      log -w "Not verifying git status"
      exit 0
    }
  fi

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi
  
  "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$GIT_STATUS_LOG"

  if [[ -v verify_all ]]; then
    verifyPythonVenv -d "$BUILD_TOP_DIR" || exit $?
    log -i "Verifying git status for all projects"

    pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
    status_out=$(repo forall -pc 'git status' | sed -e 's/project //' -e 's/\/$//' | tee -a "$GIT_STATUS_LOG") || {
      log -e "Verifying all projects failed"
      exit 1
    }
    popd &>/dev/null || exit $?
  else
    local project_dir
    if [[ ! -v project_dir_rel || -z $project_dir_rel || "$project_dir_rel" == " " ]]; then
      project_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your project directory" -o "$BUILD_TOP_DIR") || {
        log -e "Project directory to verify not set."
        exit 1
      }
      project_dir_rel=${project_dir#"$BUILD_TOP_DIR/"}
    else
      project_dir="$BUILD_TOP_DIR"/"$project_dir_rel"
    fi

    if [[ ! -d $project_dir ]]; then
      log -e "Project directory: $project_dir_rel does not exist."
      exit 1
    fi

    log -i "Verifying git status for project: $project_dir_rel"
    pushd "$project_dir" &>/dev/null || exit $?
    status_out=$(git status | tee -a "$GIT_STATUS_LOG") || {
      log -e "Verifying project failed"
      exit 1
    }
    popd &>/dev/null || exit $?
  fi

  if echo "$status_out" | grep -Eqwi 'conflicts'; then
    log -e "git status not clean, please check git_status.log for details"
    exit 1
  else
    log -i "git status clean"
  fi
}

# Show verify git status usage
_verifyGitStatusUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: verifyGitStatus [arg]
#
# Verifies the git status of all projects in repo
verifyGitStatus(){
  local project_dir_rel
  local verify_all
  local auto_verify

  local action
  if [[ ${#} -eq 0 ]]; then
    _verifyGitStatus
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
          _verifyGitStatusUsage
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
        -p|--project)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              project_dir_rel="$dir"
            else
              log -w "Empty project directory parameter"
            fi
          else
            log -w "No project directory parameter specified"
          fi
          ;;
        --all)
          shift
          verify_all=true
        ;;
        -a|--auto)
          shift
          auto_verify=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _verifyGitStatus
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./verifyGitStatus.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && verifyGitStatus "$@"
