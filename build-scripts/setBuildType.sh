#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the build type to build
#/
#/  Public Functions:
#/
#/ Usage: setBuildType [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -t, --type <build type>
#/                Build Type to build ( user | userdebug | eng )
#/
#/ EXAMPLES
#/   setBuildType
#/   setBuildType -t <build type>
#/   setBuildType --help
#/

# Ensures script is only sourced once
if [[ ${SET_BUILD_TYPE_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_BUILD_TYPE_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_BUILD_TYPE_SCRIPT_NAME ]]  || readonly SET_BUILD_TYPE_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_BUILD_TYPE_SCRIPT_DIR ]]  || readonly SET_BUILD_TYPE_SCRIPT_DIR="$( cd "$( dirname "$SET_BUILD_TYPE_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_BUILD_TYPE_SCRIPT_DIR")"/utilities/logging.sh

build_types=('eng' 'user' 'userdebug')

# Usage: _setBuildType
#
# Sets the build type
_setBuildType() {
  local eng_opt=('eng' 'Development configuration (additional debugging tools)')
  local user_opt=('user' 'Limited access for production')
  local userdebug_opt=('userdebug' 'User with root access and debuggability')

  if [[ ( ! -v BUILD_TYPE || -z $BUILD_TYPE || "$BUILD_TYPE" == " " ) &&
        ( ! -v build_type || -z $build_type || "$build_type" == " " ) ]]; then
    build_type=$("$(dirname "$SET_BUILD_TYPE_SCRIPT_DIR")"/utilities/userFunctions.sh getOption -t "Setup build type" -i "Choose your build type" -w 70 -o "${user_opt[@]}"  "${userdebug_opt[@]}" "${eng_opt[@]}" ) || {
      log -e "Setting build type cancelled by user."
      exit 1
    }
  fi
  if "$(dirname "$SET_BUILD_TYPE_SCRIPT_DIR")"/utilities/arrayFunctions.sh contains -a "${build_types[@]}" -v "$build_type"; then
    BUILD_TYPE="$build_type"
  else
    log -e "Invalid build type passed"
    return 1
  fi
  export BUILD_TYPE
}

# Show set build type usage
_setBuildTypeUsage() {
  grep '^#/' "${SET_BUILD_TYPE_SCRIPT_DIR}/${SET_BUILD_TYPE_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setBuildType [arg]
#
# Sets the build type
setBuildType(){
  local build_type
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _setBuildType
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
          _setBuildTypeUsage
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
              log -w "Empty build type parameter"
            fi
          else
            log -w "No build type parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setBuildType
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setBuildType.sh\" instead."
  exit 1
fi