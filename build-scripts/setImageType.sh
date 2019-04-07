#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets the image type to build
#/
#/  Public Functions:
#/
#/ Usage: setImageType [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -t, --type <image type>
#/                Image Type to build ( rom | boot | recovery )
#/
#/ EXAMPLES
#/   setImageType
#/   setImageType -t <image type>
#/   setImageType --help
#/

# Ensures script is only sourced once
if [[ ${SET_IMAGE_TYPE_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SET_IMAGE_TYPE_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SET_IMAGE_TYPE_SCRIPT_NAME ]]  || readonly SET_IMAGE_TYPE_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SET_IMAGE_TYPE_SCRIPT_DIR ]]  || readonly SET_IMAGE_TYPE_SCRIPT_DIR="$( cd "$( dirname "$SET_IMAGE_TYPE_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SET_IMAGE_TYPE_SCRIPT_DIR")"/utilities/logging.sh

image_types=('rom' 'boot' 'recovery')

# Usage: _setImageType
#
# Sets the image type
_setImageType() {
  local boot_opt=('boot' 'Only build boot image')
  local recovery_opt=('recovery' 'Only build recovery image')
  local rom_opt=('rom' 'Build complete rom')

  if [[ ( ! -v IMAGE_TYPE || -z $IMAGE_TYPE || "$IMAGE_TYPE" == " " ) &&
        ( ! -v image_type || -z $image_type || "$image_type" == " " ) ]]; then
    image_type=$("$(dirname "$SET_IMAGE_TYPE_SCRIPT_DIR")"/utilities/userFunctions.sh getOption -t "Build Image" -i "Choose your image type to build" -w 70 -o "${rom_opt[@]}" "${recovery_opt[@]}" "${boot_opt[@]}" ) || {
      log -e "Setting build type cancelled by user."
      exit 1
    }
  fi
  if "$(dirname "$SET_IMAGE_TYPE_SCRIPT_DIR")"/utilities/arrayFunctions.sh contains -a "${image_types[@]}" -v "$image_type"; then
    IMAGE_TYPE="$image_type"
  else
    log -e "Invalid image type passed"
    return 1
  fi
  export IMAGE_TYPE
}

# Show set image type usage
_setImageTypeUsage() {
  grep '^#/' "${SET_IMAGE_TYPE_SCRIPT_DIR}/${SET_IMAGE_TYPE_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setImageType [arg]
#
# Sets the image type
setImageType(){
  local image_type
  
  local action
  if [[ ${#} -eq 0 ]]; then
    _setImageType
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
          _setImageTypeUsage
          return 0
          ;;
        -t|--type)
          local typ="$2"
          shift # past argument
          if [[ "$typ" != '-'* ]]; then
            shift # past value
            if [[ -n $typ && "$typ" != " " ]]; then
              image_type="$typ"
            else
              log -w "Empty image type parameter"
            fi
          else
            log -w "No image type parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setImageType
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setImageType.sh\" instead."
  exit 1
fi