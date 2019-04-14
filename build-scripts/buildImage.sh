#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Builds an image
#/
#/  Public Functions:
#/
#/ Usage: buildImage [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path>
#/                Specify Top Dir for Android source
#/   -i, --image <image>
#/                Image type to build (boot | recovery | rom)
#/   -c, --device <device>
#/                Device to build for
#/   -n, --name <name>
#/                Device to build for
#/   -t, --type <type>
#/                Build type (user | userdebug | eng)
#/   -s, --statixtype <type>
#/                Statix Build type (NUCLEAR | UNOFFICIAL | OFFICIAL)
#/
#/ EXAMPLES
#/   buildImage
#/   buildImage -d <path> -i <image> -n <name> -d <device> -t <type>
#/   buildImage --help
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"
BUILD_LOG=$(dirname "$SCRIPT_DIR")/log/build.log

mkdir -p "${BUILD_LOG%/*}"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/verifyPythonVenv.sh
. "$SCRIPT_DIR"/verifyRepopick.sh
. "$(dirname "$SCRIPT_DIR")"/utilities/setTopDir.sh
. "$SCRIPT_DIR"/setBuildType.sh
. "$SCRIPT_DIR"/setBuildVariant.sh
. "$SCRIPT_DIR"/setImageType.sh
. "$SCRIPT_DIR"/setDeviceName.sh
. "$SCRIPT_DIR"/setRomName.sh


# Usage: _buildImage
#
# Builds an image file
_buildImage() {
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  if [[ ! -v ROM_NAME ]]; then
    # Set rom name
    setRomName -n "$rom_name" || exit $?
  fi
  
  if [[ ! -v DEVICE_NAME ]]; then
    # Set device name
    setDeviceName -n "$device_name" || exit $?
  fi
  
  if [[ ! -v BUILD_TYPE ]]; then
    # Set build type
    setBuildType -t "$build_type" || exit $?
  fi

  if [[ ! -v BUILD_VARIANT ]]; then
    # Set build variant
    setBuildVariant -v "$build_variant" || exit $?
  fi

  local target
  target="${ROM_NAME}"_"${DEVICE_NAME}"-"${BUILD_VARIANT}"

  if [[ ! -v IMAGE_TYPE ]]; then
    # Set image type
    setImageType -t "$image_type" || exit $?
  fi

  if [[ ! -v ANDROID_TOOLCHAIN ]]; then
    unset IFS
    pushd "$BUILD_TOP_DIR/" &>/dev/null || exit $?
    log -i "Lunching target device"
    lunch "$target" || exit $?
    popd &>/dev/null || exit $?
  fi

  "$(dirname "$SCRIPT_DIR")"/utilities/loggingFunctions.sh clearLog -f "$BUILD_LOG"

  verifyPythonVenv -d "$BUILD_TOP_DIR"
  verifyRepopick -d "$BUILD_TOP_DIR"

  local total_ram
  total_ram=$("$(dirname "$SCRIPT_DIR")"/utilities/totalMem.sh -gb)
  
  local make_jobs
  if [[ $total_ram -lt 16 ]]; then
    local cpus
    cpus=$("$(dirname "$SCRIPT_DIR")"/utilities/totalCpu.sh)
    # Depending on your ram, what you're building, and cpu
    # you can tweak this value to speed up build times
    make_jobs=$(( cpus - 3 ))
  fi

  # Build time
  local start_time
  local end_time
  pushd "$BUILD_TOP_DIR" &>/dev/null || exit $?
  # Clean types
  case "$IMAGE_TYPE" in
    rom)
      log -i "Building target rom: $target"
      # Remove previous build files
      rm -f "$ANDROID_PRODUCT_OUT"/"$ROM_NAME"_"$DEVICE_NAME"-*.zip &>/dev/null
      rm -f "$ANDROID_PRODUCT_OUT"/"$ROM_NAME"_"$DEVICE_NAME"-*.md5 &>/dev/null
      rm -f "$ANDROID_PRODUCT_OUT"/Changelog-"$ROM_NAME"_"$DEVICE_NAME"-*.md &>/dev/null

      # Set local time and date
      sed -i -e 's/DATE := $(shell date -u +%Y%m%d)/DATE := $(shell date +%Y%m%d)/g' "$BUILD_TOP_DIR"/vendor/"$ROM_NAME"/config/branding.mk
      sed -i -e 's/TIME := $(shell date -u +%H%M)/TIME := $(shell date +%H%M)/g' "$BUILD_TOP_DIR"/vendor/"$ROM_NAME"/config/branding.mk

      start_time=$(date +%s)
      if [[ $total_ram -lt 16 ]]; then
        m -j$make_jobs bacon | tee -a "$BUILD_LOG" || exit $?
      else
        mka bacon | tee -a "$BUILD_LOG" || exit $?
      fi
      end_time=$(date +%s)

      # Remove unused ota files (remove this if you provide ota updates)
      rm "$ANDROID_PRODUCT_OUT"/*-ota-*.zip &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/*.zip.md5sum &>/dev/null
      ;;
    recovery)
      rm "$ANDROID_PRODUCT_OUT"/kernel &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/recovery.img &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/recovery &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/obj/KERNEL_OBJ &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/ramdisk* &>/dev/null

      start_time=$(date +%s)
      if [[ $total_ram -lt 16 ]]; then
        m -j$make_jobs recoveryimage | tee -a "$BUILD_LOG" || exit $?
      else
        mka recoveryimage | tee -a "$BUILD_LOG" || exit $?
      fi
      end_time=$(date +%s)
      # mka ${ANDROID_PRODUCT_OUT}/recovery.img
      ;;
    system)
      rm "$ANDROID_PRODUCT_OUT"/kernel &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/recovery.img &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/recovery &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/obj/KERNEL_OBJ &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/ramdisk* &>/dev/null

      start_time=$(date +%s)
      if [[ $total_ram -lt 16 ]]; then
        m -j$make_jobs systemimage | tee -a "$BUILD_LOG" || exit $?
      else
        mka systemimage | tee -a "$BUILD_LOG" || exit $?
      fi
      end_time=$(date +%s)
      ;;
    boot)
      rm "$ANDROID_PRODUCT_OUT"/kernel &>/dev/null
      rm "$ANDROID_PRODUCT_OUT"/boot.img &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/root &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/ramdisk* &>/dev/null
      rm -rf "$ANDROID_PRODUCT_OUT"/combined* &>/dev/null

      start_time=$(date +%s)
      if [[ $total_ram -lt 16 ]]; then
        m -j$make_jobs bootimage | tee -a "$BUILD_LOG" || exit $?
      else
        mka bootimage | tee -a "$BUILD_LOG" || exit $?
      fi
      end_time=$(date +%s)

      if [ ! -e "$ANDROID_HOST_OUT"/framework/signapk.jar ]; then
        if [[ $total_ram -lt 16 ]]; then
          m -j$make_jobs signapk | tee -a "$BUILD_LOG" || exit $?
        else
          mka signapk | tee -a "$BUILD_LOG" || exit $?
        fi
      fi
      ;;
    *) log -e "Unknown build type"; exit 128; ;;
  esac
  popd &>/dev/null || exit $?

  local elapsed_time
  local elapsed_min
  local elapsed_sec
  elapsed_time=$(( end_time - start_time ))
  elapsed_min=$(( elapsed_time / 60 ))
  elapsed_sec=$(( elapsed_time - elapsed_min * 60 ))
  if [[ $elapsed_min -gt 0 ]]; then
    log -i "Build took $elapsed_min min(s) $elapsed_sec sec(s)"
  else
    log -i "Build took $elapsed_sec sec(s)"
  fi
}

# Show build image usage
_buildImageUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: buildImage [arg]
#
# Builds an image
buildImage() {
  local image_type
  local device_name
  local rom_name
  local build_type
  local build_variant

  local action
  if [[ ${#} -eq 0 ]]; then
    _buildImage
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
          _buildImageUsage
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
        -i|--image)
          local image=$2
          shift # past argument
          if [[ "$image" != '-'* ]]; then
            shift # past value
            if [[ -n $image && "$image" != " " ]]; then
              image_type="$image"
            else
              log -w "Empty image type parameter"
            fi
          else
            log -w "No image type parameter specified"
          fi
          ;;
        -c|--device)
          local device="$2"
          shift # past argument
          if [[ "$device" != '-'* ]]; then
            shift # past value
            if [[ -n $device && "$device" != " " ]]; then
              device_name="$device"
            else
              log -w "Empty device name parameter"
            fi
          else
            log -w "No device name parameter specified"
          fi
          ;;
        -n|--name)
          local name="$2"
          shift # past argument
          if [[ "$name" != '-'* ]]; then
            shift # past value
            if [[ -n $name && "$name" != " " ]]; then
              rom_name="$name"
            else
              log -w "Empty rom name parameter"
            fi
          else
            log -w "No rom name parameter specified"
          fi
          ;;
        -v|--variant)
          local var="$2"
          shift # past argument
          if [[ "$var" != '-'* ]]; then
            shift # past value
            if [[ -n $var && "$var" != " " ]]; then
              build_variant="$var"
            else
              log -w "Empty build type parameter"
            fi
          else
            log -w "No build type parameter specified"
          fi
          ;;
        -t|--type)
          local type="$2"
          shift # past argument
          if [[ "$type" != '-'* ]]; then
            shift # past value
            if [[ -n $type && "$type" != " " ]]; then
              build_type="$type"
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
    _buildImage
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./buildImage.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && buildImage "$@"
