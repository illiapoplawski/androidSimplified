#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Provides common functions to request information from the user with a GUI
#/
#/  Public Functions:
#/
#/ Usage: userFunctions [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   getDir
#/                Requests a directory from the user
#/          -t, --title "Title"
#/                Title of request dir dialog
#/          -o, --topdir <path>
#/                Directory to open file browser at
#/   getFile
#/                Requests a file from the user
#/          -t, --title "Title"
#/                Title of request file dialog
#/          -o, --topdir <path>
#/                Directory to open file browser at
#/          -e, --extension <ext>
#/                File extension(s) to select
#/          --hidden
#/                Show hidden files
#/          --multi
#/                Select multiple files
#/   getInput
#/                Requests input string from user
#/          -t, --title "Title"
#/                Title of request input dialog
#/          -d, --description "Description"
#/                Description of request input dialog
#/          -i, --initval "Default value"
#/                Default return value for request input dialog
#/          -w, --width <width>
#/                Width of request input dialog
#/          -h, --height <height>
#/                Height of request input dialog
#/   getOption
#/                Requests option from user
#/          -t, --title "Title"
#/                Title of request option dialog
#/          -d, --description "Description"
#/                Description of request option dialog
#/          -o, --options ('option' description) ...
#/                Options to present in dialog (space delimited)
#/          -w, --width <width>
#/                Width of request option dialog
#/          -h, --height <height>
#/                Height of request option dialog
#/   getPassword
#/                Requests password from user
#/          -t, --title "Title"
#/                Title of request password dialog
#/          -d, --description "Description"
#/                Description of request password dialog
#/          -w, --width <width>
#/                Width of request password dialog
#/          -h, --height <height>
#/                Height of request password dialog
#/   getYesNo
#/                Requests yes/no options from user
#/          -t, --title "Title"
#/                Title of request yes/no dialog
#/          -d, --description "Description"
#/                Description of request yes/no dialog
#/          -i, --initval [no | yes]
#/                Default option for request yes/no dialog
#/          -w, --width <width>
#/                Width of request input dialog
#/          -h, --height <height>
#/                Height of request input dialog
#/
#/ EXAMPLES
#/   userFunctions getDir -t "Title" -o <path>
#/   userFunctions getFile -t "Title" -o <path> -e <ext> [ext] --hidden --multi
#/   userFunctions getInput -d "Description" -t "Title" -i "Initial Value"
#/   userFunctions getOption  -d "Description" -t "Title" -o ('1' 'First') ('2' 'Second') -w 50 -h 20
#/   userFunctions getPassword -d "Description" -t "Title" -w 60 -h 10
#/   userFunctions getYesNo -d "Description" -t "Title" -i "no"
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh
. $(dirname "$SCRIPT_DIR")/defines/whiptail-defs.sh

# Usage: _requestDir
#
# Requests dir from the user
_requestDir() {
  local dir

  if [[ ! -v top_dir || ! -d $top_dir ]]; then
    log -w "Invalid directory passed. Setting to home"
    top_dir="$HOME"
  fi

  if dir=$("$SCRIPT_DIR"/fileBrowser.sh --directory --title "$dialog_title" --topdir "$top_dir"); then
    echo "$dir"
    exit 0
  else
    exit $?
  fi
}

# Usage: _requestFile
#
# Requests file from the user
_requestFile() {
  local file
  local ret

  if [[ ! -v top_dir || ! -d $top_dir ]]; then
    log -w "Invalid directory passed. Setting to home"
    top_dir="$HOME"
  fi

  if [[ -v multi_file ]]; then
    pushd "$HOME" &>/dev/null || exit 1
    # TODO figure out how to do multiple file selection with whiptail
    file=$(zenity --file-selection --multiple --separator=$'\n' --title="$dialog_title")
    ret=$?
    popd &>/dev/null || exit 1
  else
    if [[ -v show_hidden ]]; then
      file=$("$SCRIPT_DIR"/fileBrowser.sh -o "$top_dir" -e "${extensions[@]}" --title "$dialog_title" --hidden)
      ret=$?
    else
      file=$("$SCRIPT_DIR"/fileBrowser.sh -o "$top_dir" -e "${extensions[@]}" --title "$dialog_title")
      ret=$?
    fi
  fi
  if [[ $ret -eq 0 ]]; then
    echo "$file"
    exit 0
  else 
    exit $?
  fi
}

# Usage: _requestInput
#
# Requests input data from the user
_requestInput() {
  local input
  if input=$(whiptail --inputbox "$dialog_description" "$dialog_height" "$dialog_width" "$dialog_default_val" --title "$dialog_title" 3>&1 1>&2 2>&3-); then
    echo "$input"
    exit 0
  else
    exit $?
  fi
}

# Usage: _requestPassword
#
# Requests password from the user
_requestPassword() {
  local password
  if password=$(whiptail --passwordbox "$dialog_description" --title "$dialog_title" "$dialog_height" "$dialog_width" 3>&1 1>&2 2>&3-); then
    echo "$password"
    exit 0
  else
    exit $?
  fi
}

# Usage: _requestYesNo
#
# Requests yes no option from the user
_requestYesNo() {
  if [[ "$dialog_default_val" == "no" ]]; then
    whiptail --yesno "$dialog_description" "$dialog_height" "$dialog_width" --defaultno --title "$dialog_title" 3>&1 1>&2 2>&3-
  else
    whiptail --yesno "$dialog_description" "$dialog_height" "$dialog_width" --title "$dialog_title" 3>&1 1>&2 2>&3-
  fi
  exit $?
}

# Usage: _requestOption
#
# Requests option from the user
# Each option must contain 2 strings (a tag and an item)
_requestOption() {
  local option
  if [[ ${#dialog_options[@]} -eq 0 ]]; then
    log -e "No options provided"
    exit 1
  fi

  local menuHeight=$(( dialog_height - 8 ))
  if option=$(whiptail --title "$dialog_title" --menu "$dialog_instruction" "$dialog_height" "$dialog_width" $menuHeight "${dialog_options[@]}" 3>&1 1>&2 2>&3-); then
    echo "$option"
    exit 0
  else
    exit $?
  fi
}

# Show user functions usage info
_userFunctionsUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: userFunctions [arg]
#
# Common functions to get data from user in GUI
userFunctions(){
  local dialog_title
  local dialog_description
  local dialog_instruction
  local dialog_default_val
  local dialog_height
  local dialog_width
  local multi_file
  local dialog_options
  local top_dir
  local extensions=('ANY_EXT')

  local action
  action=$1
  shift
  case "$action" in
    -h|--help) 
      _userFunctionsUsage
      exit 0
      ;;
    getDir) 
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getDir: Empty title parameter"
              fi
            else
              log -w "getDir: No title parameter specified"
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
                log -w "getDir: No file directory parameter specified"
              fi
            fi
            ;;
          *) 
            log -w "Unknown getDir argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestDir
      ;;
    getFile) 
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getFile: Empty title parameter"
              fi
            else
              log -w "getFile: No title parameter specified"
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
                log -w "getFile: No file directory parameter specified"
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
          --hidden)
            shift
            show_hidden=true
            ;;
          --multi)
            shift
            multi_file=true
            ;;
          *) 
            log -w "Unknown getFile argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestFile
      ;;
    getInput)
      dialog_height=10
      dialog_width=70
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getInput: Empty title parameter"
              fi
            else
              log -w "getInput: No title parameter specified"
            fi
            ;;
          -i|--initval)
            local val="$2"
            shift # past argument
            if [[ "$val" != '-'* ]]; then
              shift # past value
              if [[ -n $val && "$val" != " " ]]; then
                dialog_default_val="$val"
              else
                log -w "getInput: Empty default value parameter"
              fi
            else
              log -w "getInput: No default value parameter specified"
            fi
            ;;
          -d|--description)
            local desc="$2"
            shift # past argument
            if [[ "$desc" != '-'* ]]; then
              shift # past value
              if [[ -n $desc && "$desc" != " " ]]; then
                dialog_description="$desc"
              else
                log -w "getInput: Empty description parameter"
              fi
            else
              log -w "getInput: No description parameter specified"
            fi
            ;;
          -w|--width)
            local width="$2"
            shift # past argument
            if [[ "$width" != '-'* ]]; then
              shift # past value
              if [[ -n $width && "$width" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$width"; then
                  dialog_width="$width"
                else
                  log -w "Width argument not a number. Setting default width"
                fi
              else
                log -w "getInput: Empty width parameter"
              fi
            else
              log -w "getInput: No width parameter specified"
            fi
            ;;
          -h|--height)
            local height="$2"
            shift # past argument
            if [[ "$height" != '-'* ]]; then
              shift # past value
              if [[ -n $height && "$height" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$height"; then
                  dialog_height="$height"
                else
                  log -w "Height argument not a number. Setting default height"
                fi
              else
                log -w "getInput: Empty height parameter"
              fi
            else
              log -w "getInput: No height parameter specified"
            fi
            ;;
          *) 
            log -w "Unknown getInput argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestInput
      ;;
    getOption) 
      dialog_height=15
      dialog_width=70
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getOption: Empty title parameter"
              fi
            else
              log -w "getOption: No title parameter specified"
            fi
            ;;
          -i|--instruction)
            local instr="$2"
            shift # past argument
            if [[ "$instr" != '-'* ]]; then
              shift # past value
              if [[ -n $instr && "$instr" != " " ]]; then
                dialog_instruction="$instr"
              else
                log -w "getOption: Empty instruction parameter"
              fi
            else
              log -w "getOption: No instruction parameter specified"
            fi
            ;;
          -o|--options)
            local opts
            shift # past argument
            opts=("$@")
            if [[ ${#opts[@]} -gt 0 ]]; then
              dialog_options=()
              for opt in "${opts[@]}"; do
                if [[ "$opt" != '-'* ]]; then
                  shift # past value
                  if [[ -n $opt && "$opt" != " " ]]; then
                    dialog_options+=("$opt")
                  fi
                else
                  break
                fi
              done
            fi
            ;;
          -w|--width)
            local width="$2"
            shift # past argument
            if [[ "$width" != '-'* ]]; then
              shift # past value
              if [[ -n $width && "$width" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$width"; then
                  dialog_width="$width"
                else
                  log -w "Width argument not a number. Setting default width"
                fi
              else
                log -w "getOption: Empty width parameter"
              fi
            else
              log -w "getOption: No width parameter specified"
            fi
            ;;
          -h|--height)
            local height="$2"
            shift # past argument
            if [[ "$height" != '-'* ]]; then
              shift # past value
              if [[ -n $height && "$height" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$height"; then
                  dialog_height="$height"
                else
                  log -w "Height argument not a number. Setting default height"
                fi
              else
                log -w "getOption: Empty height parameter"
              fi
            else
              log -w "getOption: No height parameter specified"
            fi
            ;;
          *) 
            log -w "Unknown getOption argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestOption
      ;;
    getPassword)
      dialog_height=10
      dialog_width=70
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getPassword: Empty title parameter"
              fi
            else
              log -w "getPassword: No title parameter specified"
            fi
            ;;
          -d|--description)
            local desc="$2"
            shift # past argument
            if [[ "$desc" != '-'* ]]; then
              shift # past value
              if [[ -n $desc && "$desc" != " " ]]; then
                dialog_description="$desc"
              else
                log -w "getPassword: Empty description parameter"
              fi
            else
              log -w "getPassword: No description parameter specified"
            fi
            ;;
          -w|--width)
            local width="$2"
            shift # past argument
            if [[ "$width" != '-'* ]]; then
              shift # past value
              if [[ -n $width && "$width" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$width"; then
                  dialog_width="$width"
                else
                  log -w "Width argument not a number. Setting default width"
                fi
              else
                log -w "getPassword: Empty width parameter"
              fi
            else
              log -w "getPassword: No width parameter specified"
            fi
            ;;
          -h|--height)
            local height="$2"
            shift # past argument
            if [[ "$height" != '-'* ]]; then
              shift # past value
              if [[ -n $height && "$height" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$height"; then
                  dialog_height="$height"
                else
                  log -w "Height argument not a number. Setting default height"
                fi
              else
                log -w "getPassword: Empty height parameter"
              fi
            else
              log -w "getPassword: No height parameter specified"
            fi
            ;;
          *) 
            log -w "Unknown getPassword argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestPassword
      ;;
    getYesNo)
      dialog_height=10
      dialog_width=70
      while [[ $# -gt 0 ]]; do
        action="$1"
        if [[ "$action" != '-'* ]]; then
          shift
          continue
        fi
        case "$action" in
          -t|--title)
            local title="$2"
            shift # past argument
            if [[ "$title" != '-'* ]]; then
              shift # past value
              if [[ -n $title && "$title" != " " ]]; then
                dialog_title="$title"
              else
                log -w "getYesNo: Empty title parameter"
              fi
            else
              log -w "getYesNo: No title parameter specified"
            fi
            ;;
          -i|--initval)
            local val="$2"
            shift # past argument
            if [[ "$val" != '-'* ]]; then
              shift # past value
              if [[ -n $val && "$val" != " " ]]; then
                dialog_default_val="$val"
              else
                log -w "getYesNo: Empty default value parameter"
              fi
            else
              log -w "getYesNo: No default value parameter specified"
            fi
            ;;
          -d|--description)
            local desc="$2"
            shift # past argument
            if [[ "$desc" != '-'* ]]; then
              shift # past value
              if [[ -n $desc && "$desc" != " " ]]; then
                dialog_description="$desc"
              else
                log -w "getYesNo: Empty description parameter"
              fi
            else
              log -w "getYesNo: No description parameter specified"
            fi
            ;;
          -w|--width)
            local width="$2"
            shift # past argument
            if [[ "$width" != '-'* ]]; then
              shift # past value
              if [[ -n $width && "$width" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$width"; then
                  dialog_width="$width"
                else
                  log -w "Width argument not a number. Setting default width"
                fi
              else
                log -w "getYesNo: Empty width parameter"
              fi
            else
              log -w "getYesNo: No width parameter specified"
            fi
            ;;
          -h|--height)
            local height="$2"
            shift # past argument
            if [[ "$height" != '-'* ]]; then
              shift # past value
              if [[ -n $height && "$height" != " " ]]; then
                if "$SCRIPT_DIR"/mathFunctions.sh isNumber "$height"; then
                  dialog_height="$height"
                else
                  log -w "Height argument not a number. Setting default height"
                fi
              else
                log -w "getYesNo: Empty height parameter"
              fi
            else
              log -w "getYesNo: No height parameter specified"
            fi
            ;;
          *) 
            log -w "Unknown getYesNo argument passed: $action. Skipping"
            shift # past argument
            ;;
        esac
      done
      _requestYesNo
      ;;
    *) log -e "Unknown arguments passed"; _userFunctionsUsage; exit 128 ;;
  esac
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./userFunctions.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && userFunctions "$@"
