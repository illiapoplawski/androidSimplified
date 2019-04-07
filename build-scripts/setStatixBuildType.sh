#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the build type for StatiXOS rom
#/
#/  Public Functions:
#/
#/ Usage: setStatixBuildType [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -t, --type <build type>
#/                Build types ( UNOFFICIAL | NUCLEAR | OFFICIAL )
#/
#/ EXAMPLES
#/   setStatixBuildType
#/   setStatixBuildType -t <build type>
#/   setStatixBuildType --help
#/

# Ensures script is only sourced once
if [[ ${SET_STATIX_BUILD_TYPE_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_STATIX_BUILD_TYPE_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_STATIX_BUILD_TYPE_SCRIPT_NAME ]]  || readonly SET_STATIX_BUILD_TYPE_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_STATIX_BUILD_TYPE_SCRIPT_DIR ]]  || readonly SET_STATIX_BUILD_TYPE_SCRIPT_DIR="$( cd "$( dirname "$SET_STATIX_BUILD_TYPE_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_STATIX_BUILD_TYPE_SCRIPT_DIR")"/utilities/logging.sh

types=('UNOFFICIAL' 'NUCLEAR' 'OFFICIAL')

# Usage: _setStatixBuildType
#
# Sets the statix build type
_setStatixBuildType() {
  local official_opt=('OFFICIAL' 'Signed official build')
  local unofficial_opt=('UNOFFICIAL' 'Unsigned testing build')
  local nuclear_opt=('NUCLEAR' 'Unsigned testing build from nuclear group')

  if [[ ( ! -v STATIX_BUILD_TYPE || -z $STATIX_BUILD_TYPE || "$STATIX_BUILD_TYPE" == " " ) &&
        ( ! -v build_type || -z $build_type || "$build_type" == " " ) ]]; then
    build_type=$("$(dirname "$SET_STATIX_BUILD_TYPE_SCRIPT_DIR")"/utilities/userFunctions.sh getOption -t "Setup statix build type" -i "Choose your build type" -w 70 -o "${unofficial_opt[@]}"  "${nuclear_opt[@]}" "${official_opt[@]}" ) || {
      log -e "Statix build type not set"
      return 1
    }
  fi

  if "$(dirname "$SET_STATIX_BUILD_TYPE_SCRIPT_DIR")"/utilities/arrayFunctions.sh contains -a "${types[@]}" -v "$build_type"; then
    STATIX_BUILD_TYPE="$build_type"
  else
    log -e "Invalid build type passed"
    return 1
  fi
  export STATIX_BUILD_TYPE
}

# Show set statix build type usage
_setStatixBuildTypeUsage() {
  grep '^#/' "${SET_STATIX_BUILD_TYPE_SCRIPT_DIR}/${SET_STATIX_BUILD_TYPE_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setStatixBuildType [arg]
#
# Sets the build type for statix rom name
setStatixBuildType(){
  local build_type

  local action
  if [[ ${#} -eq 0 ]]; then
    _setStatixBuildType
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
          _setStatixBuildTypeUsage
          return 0
          ;;
        -t|--type)
          local typ="$2"
          shift # past argument
          if [[ "$typ" != '-'* ]]; then
            shift # past value
            if [[ -n $typ && "$typ" != " " ]]; then
              build_type="$typ"
            else
              log -w "Empty statix build type parameter"
            fi
          else
            log -w "No statix build type parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setStatixBuildType
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setStatixBuildType.sh\" instead."
  exit 1
fi