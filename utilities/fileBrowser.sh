#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides a file browser to chose files and dirs from
#/
#/  Public Functions:
#/
#/ Usage: fileBrowser [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -o, --topdir <path>
#/                Directory to open browser at
#/   -e, --extension <ext>
#/                File extension(s) to select
#/   -t, --title <title>
#/                File Selection Menu Title
#/   --directory
#/                Select a directory instead of a file
#/   --hidden
#/                Show hidden files
#/
#/ EXAMPLES
#/   fileBrowser -o <path> -e <ext> -t <title>
#/   fileBrowser -o <path> -t <title> --directory
#/   fileBrowser
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh
. $(dirname "$SCRIPT_DIR")/defines/whiptail-defs.sh

# Usage: _fileBrowser
#
# Selects a file
_fileBrowser() {
  local dir_list

  if [[ -v top_dir && -n $top_dir && "$top_dir" != " " && -d $top_dir ]]; then
    cd "$top_dir" || exit $?
  fi

  local exts
  exts=${extensions[*]/#/*.}

  if [[ -v show_hidden ]]; then
    dir_list=$(ls -Agohp | grep "^d" | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
    if [[ ! -v dir_select ]]; then
      if "$SCRIPT_DIR"/arrayFunctions.sh contains -a "${extensions[@]}" -v "ANY_EXT"; then
        dir_list+=$(ls -Agoh | grep '^-' | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
      else
        dir_list+=$(ls -Agoh ${exts[*]} 2>/dev/null | grep '^-' | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
      fi
    fi
  else
    dir_list=$(ls -gohp | grep "^d" | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
    if [[ ! -v dir_select ]]; then
      if "$SCRIPT_DIR"/arrayFunctions.sh contains -a "${extensions[@]}" -v "ANY_EXT"; then
        dir_list+=$(ls -goh | grep '^-' | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
      else 
        dir_list+=$(ls -goh ${exts[*]} 2>/dev/null | grep '^-' | awk -F ' ' '{ printf("%s  |%s|\n", substr($0, index($0,$7)), $3) }')
      fi
    fi
  fi
  unset top_dir

  local cur_dir_opt=()
  if [[ -v dir_select ]]; then
    cur_dir_opt=(. 'SEL DIR')
  fi
  local back_opts=('../' 'BACK')
  local options=()
  while IFS=$'|' read -ra files; do
    for file in "${files[@]}"; do
        options+=("$file")
    done
  done <<< "$dir_list"
  unset dir_list
  
  local curdir
  curdir=$(pwd)

  if [[ "$curdir" == "/" ]]; then  # Check if you are at root folder
    selection=$(whiptail --title "$dialog_title" \
                        --menu "\nNavigate: PgUp/PgDn/Arrow\nSelect File/Folder: Enter/Tab\n$curdir" 0 0 0 \
                        --cancel-button Cancel \
                        --ok-button Select \
                        "${cur_dir_opt[@]}" "${options[@]}" 3>&1 1>&2 2>&3- | xargs)
  else   # Not Root Dir so show ../ BACK Selection in Menu
    selection=$(whiptail --title "$dialog_title" \
                        --menu "\nNavigate: PgUp/PgDn/Arrow\nSelect File/Folder: Enter/Tab\n$curdir" 0 0 0 \
                        --cancel-button "Cancel" \
                        --ok-button "Select" \
                        "${cur_dir_opt[@]}" "${back_opts[@]}" "${options[@]}" 3>&1 1>&2 2>&3- | xargs)
  fi

  if [[ $? -eq 0 ]]; then  # Check if User Selected Cancel
    if [[ -d $selection ]]; then  # Check if Directory Selected
      if [[ "$dir_select" == "true" && "$selection" == "." ]]; then
        if whiptail --title "Confirm Selection" --yesno "DirPath : $curdir" 0 0 \
                    --yes-button "Confirm" \
                    --no-button "Retry" 3>&1 1>&2 2>&3-; then
          echo "$curdir"  # Return full filepath
          exit 0
        else
          top_dir="$curdir"
        fi
      elif [[ "$selection" == "../" ]]; then
        top_dir="$(dirname "$curdir")"
      else
        top_dir="$selection"
      fi
    elif [[ -f $selection ]]; then  # Check if File Selected
      if [[ "$dir_select" != "true" ]]; then
        if whiptail --title "Confirm Selection" --yesno "DirPath : $curdir\nFileName: $selection" 0 0 \
                     --yes-button "Confirm" \
                     --no-button "Retry" 3>&1 1>&2 2>&3-; then
          echo "$curdir"/"$selection"  # Return full filepath and filename
          exit 0
        else
          top_dir="$curdir"
        fi
      fi
    else  # Could not detect a file or folder so Try Again
      whiptail --title "ERROR: Selection Error" \
               --msgbox "Error Changing to Path $selection" 0 0
      top_dir="$curdir"
    fi
  else
    exit $?
  fi
  _fileBrowser
}

# Show user functions usage info
_fileBrowserUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: userFunctions [arg]
#
# Common functions to get data from user in GUI
fileBrowser(){
  local dialog_title="File Browser"
  local top_dir
  local extensions=('ANY_EXT')
  local dir_select
  local show_hidden

  local action
  if [[ ${#} -eq 0 ]]; then
    _fileBrowser
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      if [[ "$action" != '-'* ]]; then
        shift
        continue
      fi
      case "$action" in
        -h|--help)
          _fileBrowserUsage
          exit 0
          ;;
        -t|--title)
          local title="$2"
          shift # past argument
          if [[ "$title" != '-'* ]]; then
            shift # past value
            if [[ -n $title && "$title" != " " ]]; then
              dialog_title="$title"
            else
              log -w "Empty title parameter"
            fi
          else
            log -w "No title parameter specified"
          fi
          ;;
        -o|--topdir)
          local dir=$2
          shift # past argument
          if [[ "$dir" != '-'* ]]; then
            shift # past value
            if [[ -n $dir && "$dir" != " " ]]; then
              top_dir="$dir"
            else 
              log -w "No file directory parameter specified"
            fi
          fi
          ;;
        -e|--extension)
          local exts
          shift # past argument
          exts=("$@")
          if [[ ${#exts[@]} -gt 0 ]]; then
            extensions=()
            for ext in "${exts[@]}"; do
              if [[ "$ext" != '-'* ]]; then
                shift # past value
                if [[ -n $ext && "$ext" != " " ]]; then
                  extensions+=("$ext")
                fi
              else
                break
              fi
            done
          fi
          ;;
        --directory)
          shift
          dir_select=true
          ;;
        --hidden)
          shift
          show_hidden=true
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _fileBrowser
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./fileBrowser.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && fileBrowser "$@"

