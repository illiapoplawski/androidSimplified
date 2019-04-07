#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Cherry picks commits from a Gerrit site
#/
#/  Public Functions:
#/
#/ Usage: $applyGerritCommits [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -c, --commits <commits>
#/                Commit numbers (space delimited) to cherry pick (Must be last argument)
#/   -g, --gerrit <Gerrit site>
#/                Gerrit site to cherry pick topic from
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   applyGerritCommits
#/   applyGerritCommits -d <path/to/root/dir> -g <gerrit site url> -c <commits>
#/   applyGerritCommits --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
REPOPICK_LOG="$(dirname "$SCRIPT_DIR")"/log/repopick.log

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$SCRIPT_DIR"/verifyRepopick.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _applyGerritCommits
#
# Cherry pick gerrit commits
_applyGerritCommits() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi
  
  if [[ ! -v gerrit_commits || ${#gerrit_commits[@]} -eq 0 ]]; then
    local IFS=' '
    read -r -a gerrit_commits <<< "$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Gerrit Commits" -d "Enter your commits to cherry pick\n(Space Delimited)")" || {
      log -e "No Gerrit commits specified."
      exit $?
    }
  fi

  if [[ ! -v gerrit_commits || ${#gerrit_commits[@]} -eq 0 ]]; then
    log -e "No Gerrit commits specified."
    exit 1
  fi

  for i in "${gerrit_commits[@]}"; do
    "$(dirname "$SCRIPT_DIR")"/utilities/mathFunctions.sh isInt "$i" || {
      log -e "Invalid commit number provided"
      exit $?
    }
  done

  if [[ ! -v gerrit_site || -z $gerrit_site || "$gerrit_site" == " " ]]; then
    if gerrit_site=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Gerrit Topic" -d "Enter your Gerrit site URL" -i "https://review.statixos.me" ); then
      log -i "Gerrit site set to: $gerrit_site"
    else
      log -e "Gerrit site input cancelled by user"
      exit $?
    fi
  fi

  curl -s --head "$gerrit_site" | head -n 1 | grep "200 OK" > /dev/null || {
    log -e "Code Review Site down"
    exit $?
  }

  if [[ -v reset_log ]]; then
    log -i "Resetting repopick log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$REPOPICK_LOG"
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR" || exit $?
  verifyRepopick -d "$BUILD_TOP_DIR" || exit $?

  log -i "Cherry Pick Commit(s): ${gerrit_commits[*]}"

  local log_out
  if log_out=$(repopick "${gerrit_commits[@]}" --ignore-missing --start-branch auto | tee -a "$REPOPICK_LOG"); then
    if echo "$log_out" | grep -Eqwi 'error'; then
      log -e "Failed to apply gerrit commits due to repopick errors.  Please check repopick.log for details"
      exit 1
    else
      log -i "Successfully applied gerrit commits: ${gerrit_commits[*]}"
    fi
  else
    log -e "Failed to apply gerrit commits: ${gerrit_commits[*]}"
    exit $?
  fi
}

# Show cherry pick gerrit commits usage
_applyGerritCommitsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: applyGerritCommits
#
# Cherry pick gerrit commits
applyGerritCommits(){
  local reset_log
  local gerrit_site
  local gerrit_commits
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _applyGerritCommits
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
          _applyGerritCommitsUsage
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
        -c|--commits)
          local args
          shift # past argument
          args=("$@")
          if [[ ${#args[@]} -gt 0 ]]; then
            gerrit_commits=()
            for arg in "${args[@]}"; do
              if [[ "$arg" != '-'* ]]; then
                shift # past value
                if [[ -n $arg && "$arg" != " " ]]; then
                  gerrit_commits+=("$arg")
                fi
              else
                break
              fi
            done
          fi
          ;;
        -g|--gerrit) 
          local gerrit="$2"
          shift # past argument
          if [[ "$gerrit" != '-'* ]]; then
            shift # past value
            if [[ -n $gerrit && "$gerrit" != " " ]]; then
              gerrit_site="$gerrit"
            else
              log -w "Empty gerrit site parameter"
            fi
          else
            log -w "No gerrit site parameter specified"
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
    _applyGerritCommits
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./applyGerritCommits.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && applyGerritCommits "$@"
