#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Resets projects in a repo
#/
#/  Public Functions:
#/
#/ Usage: resetProjects [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Specify Top Dir for Android source
#/   -p, --project <path>
#/                Relative path to project dir from source top
#/   --all
#/                Resets all projects
#/   --auto
#/                Bypasses user confirmtation to resets all projects
#/
#/ EXAMPLES
#/   resetProjects
#/   resetProjects -d <path/to/dir> --all
#/   resetProjects -d <path/to/dir> -p <project path>
#/   resetProjects --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _resetProjects
#
# Resets projects in a repo
_resetProjects() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v auto_reset ]]; then
    "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Reset Projects" -d "Would you like to reset all projects before applying patches?" -i "yes" || {
      log -w "Not resetting projects"
      exit 0
    }
  fi

  if [[ -v reset_all ]]; then
    verifyPythonVenv -d "$BUILD_TOP_DIR" || exit $?
    log -i "Resetting all projects"

    pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
    if repo forall -pc 'git reset --hard HEAD &>/dev/null'; then
      log -i "Reset all projects successfully."
    else
      log -e "Reset all projects failed"
      exit 1
    fi
    popd &>/dev/null || exit $?
  else
    local project_dir
    if [[ ! -v project_dir_rel || -z $project_dir_rel || "$project_dir_rel" == " " ]]; then
      project_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your project directory" -o "$BUILD_TOP_DIR") || {
        log -e "Project directory to reset not set."
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
    log -i "Resetting project: $project_dir_rel"
    pushd "$project_dir" &>/dev/null || exit $?
    if git reset --hard HEAD &>/dev/null; then
      log -i "Reset project: $project_dir_rel successfully."
    else
      log -e "Reset project: $project_dir_rel failed"
      exit 1
    fi
    popd &>/dev/null || exit $?
  fi
}

# Show reset projects usage
_resetProjectsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: resetProjects [arg]
#
# Resets projects in a repo
resetProjects(){
  local project_dir_rel
  local reset_all
  local auto_reset

  local action
  if [[ ${#} -eq 0 ]]; then
    _resetProjects
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
          _resetProjectsUsage
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
          reset_all=true
          ;;
        --auto)
          shift
          auto_reset=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _resetProjects
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./resetProjects.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && resetProjects "$@"
