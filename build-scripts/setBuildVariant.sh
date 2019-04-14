#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the build variant to build
#/
#/  Public Functions:
#/
#/ Usage: setBuildVariant [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -v, --variant <build variant>
#/                Build Variant to build ( user | userdebug | eng )
#/
#/ EXAMPLES
#/   setBuildVariant
#/   setBuildVariant -v <build variant>
#/   setBuildVariant --help
#/

# Ensures script is only sourced once
if [[ ${SET_BUILD_VARIANT_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_BUILD_VARIANT_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_BUILD_VARIANT_SCRIPT_NAME ]]  || readonly SET_BUILD_VARIANT_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_BUILD_VARIANT_SCRIPT_DIR ]]  || readonly SET_BUILD_VARIANT_SCRIPT_DIR="$( cd "$( dirname "$SET_BUILD_VARIANT_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_BUILD_VARIANT_SCRIPT_DIR")"/utilities/logging.sh

build_variants=('eng' 'user' 'userdebug')

# Usage: _setBuildVariant
#
# Sets the build variant
_setBuildVariant() {
  local eng_opt=('eng' 'Development configuration (additional debugging tools)')
  local user_opt=('user' 'Limited access for production')
  local userdebug_opt=('userdebug' 'User with root access and debuggability')

  if [[ ( ! -v BUILD_VARIANT || -z $BUILD_VARIANT || "$BUILD_VARIANT" == " " ) &&
        ( ! -v build_variant || -z $build_variant || "$build_variant" == " " ) ]]; then
    build_variant=$("$(dirname "$SET_BUILD_VARIANT_SCRIPT_DIR")"/utilities/userFunctions.sh getOption -t "Setup build variant" -i "Choose your build variant" -w 70 -o "${user_opt[@]}"  "${userdebug_opt[@]}" "${eng_opt[@]}" ) || {
      log -e "Setting build variant cancelled by user."
      exit 1
    }
  fi
  if "$(dirname "$SET_BUILD_VARIANT_SCRIPT_DIR")"/utilities/arrayFunctions.sh contains -a "${build_variants[@]}" -v "$build_variant"; then
    BUILD_VARIANT="$build_variant"
  else
    log -e "Invalid build variant passed"
    return 1
  fi
  export BUILD_VARIANT
}

# Show set build variant usage
_setBuildVariantUsage() {
  grep '^#/' "${SET_BUILD_VARIANT_SCRIPT_DIR}/${SET_BUILD_VARIANT_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setBuildVariant [arg]
#
# Sets the build variant
setBuildVariant(){
  local build_variant
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _setBuildVariant
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
          _setBuildVariantUsage
          return 0
          ;;
        -v|--variant)
          local var="$2"
          shift # past argument
          if [[ "$var" != '-'* ]]; then
            shift # past value
            if [[ -n $var && "$var" != " " ]]; then
              build_variant="$var"
            else
              log -w "Empty build variant parameter"
            fi
          else
            log -w "No build variant parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setBuildVariant
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setBuildVariant.sh\" instead."
  exit 1
fi