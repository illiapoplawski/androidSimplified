#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the environment locale
#/
#/  Public Functions:
#/
#/ Usage: cleanOutput [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Directory to save changelog to
#/   -l, --locale [locale]
#/                Locale to set (no param resets locale)
#/
#/ EXAMPLES
#/   setLocale
#/   setLocale -l C
#/   setLocale -l
#/   setLocale --help
#/

# Ensures script is only sourced once
if [[ ${SET_LOCALE_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_LOCALE_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_LOCALE_SCRIPT_NAME ]]  || readonly SET_LOCALE_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_LOCALE_SCRIPT_DIR ]]  || readonly SET_LOCALE_SCRIPT_DIR="$( cd "$( dirname "$SET_LOCALE_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_LOCALE_SCRIPT_DIR")"/utilities/logging.sh

# Usage: _setLocale
#
# Sets the environment locale
_setLocale() {
  if [[ ! -v locale ]]; then
    locale=$("$(dirname "$SET_LOCALE_SCRIPT_DIR")"/utilities/userFunctions.sh getInput -t "Set Locale" -d "Locale of \"C\" is recommended for building AOSP\nNot setting a locale resets the system locale" -i "C") || {
      return $?
    }
  fi

  # Description of how locale works
  # https://unix.stackexchange.com/questions/87745/what-does-lc-all-c-do/87763#87763
  export LC_ALL="$locale"
  log -i "Locale set to: $locale"
}

# Show set locale usage
_setLocaleUsage() {
  grep '^#/' "${SET_LOCALE_SCRIPT_DIR}/${SET_LOCALE_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setLocale [arg]
#
# Sets the locale
setLocale(){
  local locale
  local action
  if [[ ${#} -eq 0 ]]; then
    _setLocale
  else
    action="$1"
    case "$action" in
      -h|--help) 
        shift
        _setLocaleUsage
        return 0
        ;;
      -l|--locale)
        local loc="$2"
        shift # past argument
        if [[ "$loc" != '-'* ]]; then
          locale="$loc"
          shift # past value
        else
          log -i "No locale parameter specified. Resetting locale"
          unset locale
        fi
        ;;
      *) 
        log -w "Unknown argument passed: $action. Skipping"
        shift # past argument
        ;;
      esac
    _setLocale
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setLocale.sh\" instead."
  exit 1
fi