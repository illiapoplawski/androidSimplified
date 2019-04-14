#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Applies a series of patches from a file
#/
#/ Usage: applyPatches [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -p, --patchfile <path/to/file>
#/                Specify patch file with all patches to apply
#/   -b, --basedir <path/to/dir>
#/                Top dir for android source code
#/   -l, --patchdir <path/to/dir>
#/                Dir where local patch files are stored
#/   -g, --gerrit <gerrit url>
#/                Gerrit site to cherry pick from
#/
#/ EXAMPLES
#/   applyPatches
#/   applyPatches -h
#/   applyPatches -p <path/to/file> -b <path> -l <path/to/local/patches> -g <gerrit site url>
#/
#/ PATCH FILE SYNTAX
#/   #Comment line                                           // Comment
#/   123456 123457                                                           // Cherry pick specific change-ids
#/   checkout local/path GithubAccount/repoName refs/for/9                   // Do a github checkout of HEAD
#/   checkout local/path GithubAccount/repoName refs/for/9 commitHash        // Do a github checkout of specific commit
#/   cherrypick local/path GithubAccount/repoName refs/for/9 commitHash      // Do a github cherrypick of specific commit
#/   revert local/path commitHash                                            // Do a github revert of specific commit
#/   topic topic-name                                                        // Cherry pick all changes with specific topic
#/   local local/path 0001-patch-file.patch                                  // Apply local patch
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
REPOPICK_LOG=$(dirname "$SCRIPT_DIR")/log/repopick.log

mkdir -p "${REPOPICK_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$SCRIPT_DIR"/verifyRepopick.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _applyPatches [arg]
#
# Applies patches from github, gerrit, or local to source
_applyPatches() {
  local patch_file

  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v patch_dir || -z $patch_dir || "$patch_dir" == " " || ! -d $patch_dir ||
        ! -v patch_file_name || -z $patch_file_name || "$patch_file_name" == " " ||
        ! -v gerrit_site || -z $gerrit_site || "$gerrit_site" == " " ]]; then
    "$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Apply Patches" -d "Would you like to apply patches before building?" || {
      log -i "Not applying patches"
      exit 0
    }
  fi
  
  patch_dir=${patch_dir%/}
  if [[ ! -v patch_dir || -z $patch_dir || "$patch_dir" == " " || ! -d $patch_dir ||
        ! -v patch_file_name || -z $patch_file_name || "$patch_file_name" == " " ]]; then
    patch_file=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getFile -t "Select your patch file" -o "$BUILD_TOP_DIR") || {
      log -w "Patch file not specified.  Not applying patches"
      exit 0
    }
    patch_dir=$(dirname "$patch_file")
    patch_file_name=${patch_file##*/}
  else
    patch_file="$patch_dir"/"$patch_file_name"
  fi

  if [[ ! -s $patch_file ]]; then
    log -i "Patch file is empty.  No patches applied!"
    exit 0
  fi

  if [[ ! -v gerrit_site || -z $gerrit_site || "$gerrit_site" == " " ]]; then
    if gerrit_site=$("$(dirname "$SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Gerrit Commits" -d "Enter your Gerrit site URL" -i "https://review.statixos.me"); then
      log -i "Gerrit site set to: $gerrit_site"
    else
      log -e "Gerrit site input cancelled by user"
      exit 1
    fi
  fi

  curl -s --head "$gerrit_site" | head -n 1 | grep "200 OK" > /dev/null || {
    log -e "Code Review Site down"
    exit 1
  }

  "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$REPOPICK_LOG"
  
  verifyPythonVenv -d "$BUILD_TOP_DIR"

  log -i "Applying patches from: $patch_file_name"

  # Create auto branch
  repo abandon auto

  # Read patch data
  while read -r line; do
    case $line in
      checkout*)
        local IFS=' '; read -ra data <<< "$line"
        local acc_name
        local repo_name
        acc_name=$(echo "${data[2]}" | cut -d'/' -f1)
        repo_name=$(echo "${data[2]}" | cut -d'/' -f2)
        "$SCRIPT_DIR"/applyGithubCheckout.sh -d "$BUILD_TOP_DIR" -t "${data[1]}" -a "$acc_name" -r "$repo_name" -b "${data[3]}" -c "${data[4]}"
        ;;
      cherrypick*)
        local IFS=' '; read -ra data <<< "$line"
        local acc_name
        local repo_name
        acc_name=$(echo "${data[2]}" | cut -d'/' -f1)
        repo_name=$(echo "${data[2]}" | cut -d'/' -f2)
        "$SCRIPT_DIR"/applyGithubCherrypick.sh -d "$BUILD_TOP_DIR" -t "${data[1]}" -a "$acc_name" -r "$repo_name" -b "${data[3]}" -c "${data[4]}"
        ;;
      revert*)
        local IFS=' '; read -ra data <<< "$line"
        "$SCRIPT_DIR"/revertGithubCommit.sh -d "$BUILD_TOP_DIR" -t "${data[1]}" -c "${data[2]}"
        ;;
      local*)
        local IFS=' '; read -ra data <<< "$line"
        "$SCRIPT_DIR"/applyLocalPatch.sh -d "$BUILD_TOP_DIR" -t "${data[1]}" -p "$patch_dir" -n "${data[2]}"
        ;;
      [0-9]*)
        local IFS=' '; read -ra data <<< "$line"
        "$SCRIPT_DIR"/applyGerritCommits.sh -d "$BUILD_TOP_DIR" -g "$gerrit_site" -c "${data[@]}"
        ;;
      topic*)
        local IFS=' '; read -ra data <<< "$line"
        "$SCRIPT_DIR"/applyGerritTopic.sh -d "$BUILD_TOP_DIR" -t "${data[1]}" -g "$gerrit_site"
        ;;
      sync)
        "$SCRIPT_DIR"/syncRepo.sh -d "$BUILD_TOP_DIR"
        ;;
    esac
  done < "$patch_file"
  log -i "Applying patches completed"
}

# Show apply patches usage info
_applyPatchesUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: applyPatches [arg]
#
# Applies patches from github, gerrit, or local to source
applyPatches(){
  local patch_file_name
  local patch_dir
  local gerrit_site

  local action
  if [[ ${#} -eq 0 ]]; then
    _applyPatches
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
          _applyPatchesUsage
          exit 0
         ;;
        -b|--basedir) 
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
        -l|--patchdir) 
          local patchdir="$2"
          shift # past argument
          if [[ "$patchdir" != '-'* ]]; then
            shift # past value
            if [[ -n $patchdir && "$dir" != " " ]]; then
              patch_dir="$patchdir"
            else 
              log -w "No patch directory parameter specified"
            fi
          fi
          ;;
        -p|--patchfile) 
          local name="$2"
          shift # past argument
          if [[ "$name" != '-'* ]]; then
            shift # past value
            if [[ -n $name && "$name" != " " ]]; then
              patch_file_name="$name"
            else
              log -w "Empty patch file name parameter"
            fi
          else
            log -w "No patch file name parameter specified"
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
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _applyPatches
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./applyPatches.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && applyPatches "$@"
