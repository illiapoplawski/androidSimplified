#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Generates a changelog
#/
#/  Public Functions:
#/
#/ Usage: generateChangelog [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory to save changelog to
#/   -n, --name <name>
#/                Name of changelog file
#/   -c, --days <int>
#/                Number of days for which to generate changelog
#/
#/ EXAMPLES
#/   generateChangelog
#/   generateChangelog -d <path/to/dir> -n <name> -c 8
#/   generateChangelog --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _generateChangelog
#
# Generates a changelog
_getChangelogDays() {
  local currentDate
  currentDate=$(date +%s)
  local lastDate
  lastDate=$(zenity --calendar --date-format=%s) || {
    local ret=$?
    log -e "Choosing start of changelog cancelled by user: $?"
    exit $ret
  }
  typeset -i daysDiff
  local daysDiff=$(( (currentDate-lastDate)/86400 ))
  printf -v daysDiffInt '%d' "$daysDiff" 2>/dev/null
  echo "$daysDiffInt"
  exit 0
}

# Usage: _generateChangelog
#
# Generates a changelog
_generateChangelog() {
    setTopDir -d "$BUILD_TOP_DIR" || exit $?

  if [[ ! -v changelog_dir || -z $changelog_dir || "$changelog_dir" == " " ]]; then
    if changelog_dir=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose where to save your changelog file" -o "$BUILD_TOP_DIR"); then
      log -i "Changelog Directory set to $changelog_name_no_path."
    else
      log -e "Changelog Directory not specified. Not generating changelog"
      exit 0
    fi
  fi
  changelog_dir=${changelog_dir%/}
  if [[ ! -d $changelog_dir ]]; then
    log -e "Changelog Directory: $changelog_dir does not exist."
    exit 1
  fi

  if [[ ! -v changelog_name_no_path || -z $changelog_name_no_path || "$changelog_name_no_path" == " " ]]; then
    if changelog_name_no_path=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Changelog" -d "Enter the name of your changelog file"); then
      log -i "Changelog File Name set to $changelog_name_no_path."
    else
      log -e "Changelog File Name not specified. Not generating changelog"
      exit 0
    fi
  fi
  changelog_file="$changelog_dir"/Changelog-"${changelog_name_no_path%.*}".md

  if [[ -s $changelog_file ]]; then
    log -i "Clearing old change log"
    : > "$changelog_file"
  else
    touch "$changelog_file"
  fi
  iconv -f "ascii" -t "UTF-8" "$changelog_file" -o "$changelog_file"

  if [[ ! -v changelog_days || -z $changelog_days || "$changelog_days" == " " ]]; then
    changelog_days=$(_getChangelogDays) || exit $?
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR"

  log -i "Generating Changelog"

  local sinceDate
  local untilDate
  for i in $( seq "$changelog_days" ); do
    # Update new date range going downwards from current date
    sinceDate=$(date --date="$i days ago" +%Y-%m-%d)
    untilDate=$(date --date="$(( i - 1 )) days ago" +%Y-%m-%d)
    
    # Cycle through every repo to find commits between 2 dates
    # Initial formating of commits is done while reading it to remove project/ from repo name and remove trailing /
    local dayChanges
    dayChanges=$(repo forall -pc 'git log --pretty=format:"   - %s" --since='"$sinceDate"' --until='"$untilDate"' --date=short' | sed -e 's/project / \xe2\x80\xa2 /' -e 's/\/$//')
    local changesCount
    changesCount=$(echo -e "$dayChanges" | wc -l)
    # If commits occurred on those dates, write date and commits to file
    if [[ $changesCount -gt 1 ]]; then
      # Display date for next commits
      echo -e "\n====================\n     $untilDate\n====================" >> "$changelog_file"
      echo -e "$dayChanges" >> "$changelog_file"
    fi
  done

  sed -i "1 i\CHANGELOG - $changelog_name_no_path" "$changelog_file" # Insert ROM name to top of file
  log -i "Changelog generated"
}

# Show generate changelog usage
_generateChangelogUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: generateChangelog [arg]
#
# Generates a changelog
generateChangelog(){
  local changelog_dir
  local changelog_file
  local changelog_name_no_path
  local changelog_days
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _generateChangelog
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
          _generateChangelogUsage
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
        -o|--outdir)
          local dir="$2"
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              changelog_dir="$dir"
            else 
              log -w "No changelog directory parameter specified"
            fi
          fi
          ;;
        -n|--name)
          local name="$2"
          shift # past argument
          if [[ "$name" != '-'* ]]; then
            shift # past value
            if [[ -n $name && "$name" != " " ]]; then
              changelog_name_no_path="$name"
            else
              log -w "Empty changelog name parameter"
            fi
          else
            log -w "No changelog name parameter specified"
          fi
          ;;
        -c|--days)
          local days="$2"
          shift # past argument
          if [[ "$days" != '-'* ]]; then
            shift # past value
            if [[ -n $days && "$days" != " " ]]; then
              changelog_days="$days"
            else
              log -w "Empty changelog days parameter"
            fi
          else
            log -w "No changelog days parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _generateChangelog
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./generateChangelog.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && generateChangelog "$@"
