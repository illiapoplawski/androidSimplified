#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Initializes a rom repo
#/
#/  Public Functions:
#/
#/ Usage: $initRomRepo [OPTIONS]...
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
#/
#/ EXAMPLES
#/   initRomRepo
#/   initRomRepo -d <path/to/root/dir> -a <GithubAcc> -m <manifest_repo_name> -b <branch>
#/   initRomRepo --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh

# Usage: _initRomRepo
#
# Initialize a Rom repo
_initRomRepo() {
  local manifest_url
  
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v account_name || -z $account_name || "$account_name" == " " ||
        ! -v manifest_name || -z $manifest_name || "$manifest_name" == " " ]]; then
    manifest_url=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Initialize Rom Repo" -d "Input URL for manifest repo of rom") || {
      log -e "Githut manifest URL not specified."
      exit 1
    }
    account_name=$(echo "$manifest_url" | cut -d'/' -f4)
    manifest_name=$(echo "$manifest_url" | cut -d'/' -f5)

    if [[ -z $account_name || "$account_name" == " " ||
          -z $manifest_name || "$manifest_name" == " " ]]; then
      log -e "A github account and manifest repo must be specified."
      exit 1
    fi
  fi

  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    branch=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Initialize Rom Repo" -d "Input rom branch to initialize")
  fi

  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    log -e "Branch not set."
    exit 1
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR"

  # Navigate to target
  pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
  log -i "Initializing rom: $account_name"
  repo init -u https://github.com/"${account_name}"/"${manifest_name}".git -b "$branch"
  popd &>/dev/null || exit $? 
}

# Show init rom repo usage
_initRomRepoUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: initRomRepo [args]
#
# Initialize Rom Repo
initRomRepo(){
  local manifest_name
  local account_name
  local branch

  local action
  if [[ ${#} -eq 0 ]]; then
    _initRomRepo
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      if [[ "$action" != '-'* ]]; then
        shift
        continue
      fi
      case $action in
        -h|--help)
          shift
          _initRomRepoUsage
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
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _initRomRepo
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./initRomRepo.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && initRomRepo "$@"
