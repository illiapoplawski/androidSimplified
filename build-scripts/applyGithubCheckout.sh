#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Checks out a commit or HEAD from a github repo
#/
#/  Public Functions:
#/
#/ Usage: $applyGithubCheckout [argument]
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -t, --target <relative/path/to/target/dir>
#/                Target dir for checkout (relative to Top Dir)
#/   -a, --account <Github account>
#/                Github account name
#/   -r, --repo <repo_name>
#/                Github repo name
#/   -b, --branch <ref>
#/                Branch to checkout commit from
#/   -c, --hash [hash]
#/                HASH of commit
#/   --reset
#/                Clears the log
#/
#/ EXAMPLES
#/   applyGithubCheckout
#/   applyGithubCheckout -d <path/to/root/dir> -t <relative/path/to/target/dir> -a <GithubAcc> -r <repo_name> -b <branch> -c [hash]
#/   applyGithubCheckout --help
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
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _applyGithubCheckout
#
# Checkout a github commit
_applyGithubCheckout() {
  local checkout_target
  local commit_url

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi
  
  if [[ ! -v checkout_target_rel || -z $checkout_target_rel || "$checkout_target_rel" == " " ]]; then
    checkout_target=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getDir -t "Choose your checkout commit's target directory" -o "$BUILD_TOP_DIR") || {
      log -e "Checkout commit target dir not specified."
      exit 1
    }
    checkout_target_rel=${checkout_target#"$BUILD_TOP_DIR/"}
  else
    checkout_target="$BUILD_TOP_DIR"/"$checkout_target_rel"
  fi

  if [[ ! -d $checkout_target ]]; then
    log -e "Revert target directory: ${checkout_target_rel} does not exist."
    exit 1
  fi

  if [[ ! -v account_name || -z $account_name || "$account_name" == " " ||
        ! -v repo_name || -z $repo_name || "$repo_name" == " " ]]; then
    commit_url=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Checkout Github Commit" -d "Input URL for commit to apply checkout from\nIf no specific commit is chosen then the repo HEAD will be fetched") || {
      log -e "Github commit URL not specified."
      exit 1
    }

    account_name=$(echo "$commit_url" | cut -d'/' -f4)
    repo_name=$(echo "$commit_url" | cut -d'/' -f5)
    commit_hash=$(echo "$commit_url" | cut -d'/' -f7)
    if [[ -z $account_name || "$account_name" == " " ||
          -z $repo_name || "$repo_name" == " " ]]; then
      log -e "A github account and repo must be specified."
      exit 1
    fi
    if [[ ! -v commit_hash || -z $commit_hash || "$commit_hash" == " " ]]; then
      commit_hash=FETCH_HEAD
    fi
  fi

  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    branch=$( "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Checkout Github Commit" -d "Input repo branch to checkout from" )
  fi
  
  if [[ ! -v branch || -z $branch || "$branch" == " " ]]; then
    log -i "Branch not set.  Fetching all branches"
  fi

  if [[ -v reset_log ]]; then
    log -i "Resetting repopick log"
    "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$REPOPICK_LOG"
  fi

  verifyPythonVenv -d "$BUILD_TOP_DIR"

  pushd "$checkout_target" &>/dev/null || exit $?
  log -i "Performing checkout from git repo $repo_name"

  # Create auto branch
  repo start auto

  if log_out=$(git fetch https://github.com/"${account_name}"/"${repo_name}" "$branch" && git checkout "$commit_hash" | tee -a "$REPOPICK_LOG"); then 
    if echo "$log_out" | grep -Eqwi 'error'; then
      log -e "Failed to apply github checkout due to repopick errors.  Please check repopick.log for details"
      exit 1
    else
      log -i "Successfully applied github checkout from: $repo_name"
    fi
  else
    log -e "Failed to apply github checkout from: $repo_name"
    exit 1
  fi
  popd &>/dev/null || exit $?
}

# Show checkout github commit usage
_applyGithubCheckoutUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: applyGithubCheckout
#
# Checkout a github commit
applyGithubCheckout(){
  local checkout_target_rel
  local account_name
  local repo_name
  local commit_hash
  local branch
  local reset_log

  local action
  if [[ ${#} -eq 0 ]]; then
    _applyGithubCheckout
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
          _applyGithubCheckoutUsage
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
          local target="$2"
          shift # past argument
          if [[ "$target" != '-'* ]]; then
            shift # past value
            if [[ -n $target && "$target" != " " ]]; then
              checkout_target_rel="$target"
            else
              log -w "Empty target directory parameter"
            fi
          else
            log -w "No target directory parameter specified"
          fi
          ;;
        -c|--hash)
          local hash="$2"
          shift # past argument
          if [[ -z $hash || "$hash" == " " || "$hash" == '-'* ]]; then
            commit_hash=FETCH_HEAD
          else
            commit_hash="$hash"
            shift # past value
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
        --reset)
          shift # past argument
          reset_log=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _applyGithubCheckout
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./applyGithubCheckout.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && applyGithubCheckout "$@"
