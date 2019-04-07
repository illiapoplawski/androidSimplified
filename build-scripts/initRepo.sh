#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Initializes a repository
#/
#/  Public Functions:
#/
#/ Usage: initRepo [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Specify Top Dir for Android source
#/   -a, --account <Github account>
#/                Github account name
#/   -r, --repo <repo_name>
#/                Github repo name
#/   -b, --branch <ref>
#/                Branch to checkout commit from
#/
#/ EXAMPLES
#/   initRepo
#/   initRepo -d <path/to/dir> -a <GithubAcc> -r <repo_name> -b <branch>
#/   initRepo --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh

# Usage: _initRepo
#
# Initializes a repo
_initRepo() {
  local manifest_url
  
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v account_name || -z $account_name || "$account_name" == " " ||
        ! -v repo_name || -z $repo_name || "$repo_name" == " " ]]; then
    manifest_url=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Initialize ROM repo" -d "Input URL for Rom manifest repo to initialize") || {
      log -e "ROM manifest repo URL not specified."
      exit 1
    }

    account_name=$(echo "$manifest_url" | cut -d'/' -f4)
    repo_name=$(echo "$manifest_url" | cut -d'/' -f5)
    if [[ -z $account_name || "$account_name" == " " ||
          -z $repo_name || "$repo_name" == " " ]]; then
      log -e "A github account and repo must be specified."
      exit 1
    fi
  fi

  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    branch=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Initialize ROM repo" -d "Input branch to initialize for rom" )
  fi
  
  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    log -i "Branch not set"
    exit 1
  fi

  # Enable Python 2.7 virtual environment
  verifyPythonVenv || exit $?

  pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
  if repo init -u https://github.com/"$account_name"/"$repo_name" -b "$branch"; then
    log -i "Repo initialized successfully"
  else
    log -e "Repo initialization failed!"
    exit 1
  fi
  popd &>/dev/null || exit $?
}

# Show init repo usage
_initRepoUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: initRepo [arg]
#
# Initializes a repo
initRepo(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _initRepo
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
          _initRepoUsage
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
        -r|--repo)
          local repo="$2"
          shift # past argument
          if [[ "$repo" != '-'* ]]; then
            shift # past value
            if [[ -n $repo && "$repo" != " " ]]; then
              repo_name="$repo"
            else
              log -w "Empty repo name parameter"
            fi
          else
            log -w "No repo name parameter specified"
          fi
          ;;
        -a|--account)
          local acc="$2"
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
          local branch="$2"
          shift # past argument
          if [[ "$branch" != '-'* ]]; then
            shift # past value
            if [[ -n $branch && "$branch" != " " ]]; then
              branch="$branch"
            else
              log -w "Empty branch name parameter"
            fi
          else
            log -w "No branch name parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _initRepo
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./initRepo.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && initRepo "$@"
