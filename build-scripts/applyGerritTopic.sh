#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Cherry picks a topic from a Gerrit site
#/
#/  Public Functions:
#/
#/ Usage: $applyGerritTopic [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -t, --topic <topic name>
#/                Topic name to cherry pick
#/   -g, --gerrit <Gerrit site>
#/                Gerrit site to cherry pick topic from
#/   -r, --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   applyGerritTopic
#/   applyGerritTopic -d <path/to/root/dir> -t <topic name> -g <gerrit site url>
#/   applyGerritTopic --help
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
. "$SCRIPT_DIR"/verifyRepopick.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _applyGerritTopic
#
# Cherry pick a gerrit topic
_applyGerritTopic() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v gerrit_topic || -z $gerrit_topic || "$gerrit_topic" == " " ]]; then
    if gerrit_topic=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Gerrit Topic" -d "Enter your topic to cherry pick" ); then
      if [[ ! -v gerrit_topic || -z $gerrit_topic || "$gerrit_topic" == " " ]]; then
        log -e "Gerrit topic not specified."
        exit 1
      else
        log -i "Setting gerrit topic to $gerrit_topic"
      fi
    else
      log -e "Gerrit commit input cancelled by user"
      exit $?
    fi
  fi

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

  log -i "Cherry Pick Topic: ${gerrit_topic}"
  
  local log_out
  if log_out=$(repopick -t "${gerrit_topic}" --ignore-missing --start-branch auto | tee -a "$REPOPICK_LOG"); then
    if echo "$log_out" | grep -Eqwi 'error'; then
      log -e "Failed to apply gerrit topic due to repopick errors.  Please check repopick.log for details"
      exit 1
    else
      log -i "Successfully applied gerrit topic: $gerrit_topic"
    fi
  else
    log -e "Failed to apply gerrit topic: $gerrit_topic"
    exit $?
  fi
}

# Show cherry pick gerrit topic usage
_applyGerritTopicUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: applyGerritTopic
#
# Cherry pick a gerrit topic
applyGerritTopic(){
  local reset_log
  local gerrit_site
  local gerrit_topic
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _applyGerritTopic
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
          _applyGerritTopicUsage
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
        -t|--topic)
          local topic="$2"
          shift # past argument
          if [[ "$topic" != '-'* ]]; then
            shift # past value
            if [[ -n $topic && "$topic" != " " ]]; then
              gerrit_topic="$topic"
            else
              log -w "Empty gerrit topic parameter"
            fi
          else
            log -w "No gerrit topic parameter specified"
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
    _applyGerritTopic
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./applyGerritTopic.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && applyGerritTopic "$@"
