#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: buildRomGUI [OPTIONS]...
#/
#/ 
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/
#/ EXAMPLES
#/   buildRomGUI -h
#/   buildRomGUI
#/  

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh
. "$SCRIPT_DIR"/utilities/verifyPythonVenv.sh
. "$SCRIPT_DIR"/utilities/setTopDir.sh
. "$SCRIPT_DIR"/build-scripts/verifyRepopick.sh
. "$SCRIPT_DIR"/build-scripts/setupCCache.sh
. "$SCRIPT_DIR"/build-scripts/setupJack.sh
. "$SCRIPT_DIR"/build-scripts/setupNinja.sh
. "$SCRIPT_DIR"/build-scripts/setStatixBuildType.sh
. "$SCRIPT_DIR"/build-scripts/setBuildType.sh
. "$SCRIPT_DIR"/build-scripts/setImageType.sh
. "$SCRIPT_DIR"/build-scripts/setDeviceName.sh
. "$SCRIPT_DIR"/build-scripts/setRomName.sh
. "$SCRIPT_DIR"/build-scripts/setOutDir.sh
. "$SCRIPT_DIR"/build-scripts/setLocale.sh
. "$SCRIPT_DIR"/build-scripts/setUploadDir.sh

# Usage: _buildRomGUI
#
# Sets up build environment, applies patches, builds rom, generates changelog, and uploads rom
_buildRomGUI() {
  # Set build top dir
  setTopDir || exit $?

  # Set out dir
  setOutDir || exit $?

  # Enable Python 2.7 virtual environment
  verifyPythonVenv || exit $?

  # Setup build environment
  verifyRepopick || exit $?

  # Set locale
  setLocale || exit $?

  # Setup ccache env variables
  setupCCache || exit $?

  # Clear ccache
  "$SCRIPT_DIR"/build-scripts/clearCCache.sh || exit $?

  # Set ccache size
  "$SCRIPT_DIR"/build-scripts/setCCacheSize.sh || exit $?

  # Setup Ninja
  setupNinja || exit $?

  # Setup Jack
  setupJack || exit $?

  # Reset projects
  "$SCRIPT_DIR"/build-scripts/resetProjects.sh --all || exit $?

  # Sync repo
  "$SCRIPT_DIR"/build-scripts/syncRepo.sh || exit $?

  # Apply patches
  "$SCRIPT_DIR"/build-scripts/applyPatches.sh || exit $?

  # Verify git status
  "$SCRIPT_DIR"/build-scripts/verifyGitStatus.sh --all || exit $?

  # Set rom name
  setRomName || exit $?

  # Set device name
  setDeviceName || exit $?

  # Set statix build type
  setStatixBuildType || exit $?

  # Set build type
  setBuildType || exit $?

  # Set image type
  setImageType || exit $?

  local target
  target="${ROM_NAME}"_"${DEVICE_NAME}"-"${BUILD_TYPE}"

  unset IFS
  pushd "$BUILD_TOP_DIR/" &>/dev/null || exit $?
  log -i "Lunching target device"
  lunch "$target" || exit $?
  popd &>/dev/null || exit $?

  # Clean output
  "$SCRIPT_DIR"/build-scripts/cleanOutput.sh || exit $?

  # Setup Swap (hopefully disable)
  "$SCRIPT_DIR"/build-scripts/setupSwap.sh || exit $?

  # Build image
  "$SCRIPT_DIR"/build-scripts/buildImage.sh || exit $?

  local file_name
  file_name=$(find "$ANDROID_PRODUCT_OUT" -maxdepth 1 -name "*_*-*.zip" -type f | sort | tail -1) || exit $?
  file_name=${file_name##*/}

  local file_device_name
  file_device_name=${file_name%%-*}

  # Generate MD5
  "$SCRIPT_DIR"/build-scripts/generateMD5.sh -f "$ANDROID_PRODUCT_OUT"/"$file_name" || exit $?

  "$SCRIPT_DIR"/utilities/userFunctions.sh getYesNo -t "Generate Changelog" -d "Would you like to generate a changelog?" -i "yes" && {
    # Generate Changelog
    "$SCRIPT_DIR"/build-scripts/generateChangelog.sh -o "$ANDROID_PRODUCT_OUT" -n "$file_name" || exit $?
  }
  
  "$SCRIPT_DIR"/utilities/userFunctions.sh getYesNo -t "Upload ROM" -d "Would you like to upload the ROM?" -i "yes" && {
    # Set upload dir
    setUploadDir || exit $?

    # Archive old files
    "$SCRIPT_DIR"/build-scripts/archiveFile.sh -f "${UPLOAD_DIR}/*.*" -d "${UPLOAD_DIR}/Archive" || exit $?

    # Upload rom
    "$SCRIPT_DIR"/build-scripts/uploadFile.sh -f "$ANDROID_PRODUCT_OUT"/"$file_name" || exit $?

    # Delete old files
    "$SCRIPT_DIR"/build-scripts/deleteFiles.sh -d "$UPLOAD_DIR"/Archive -p "$file_device_name-*.zip" "$file_device_name-*.md5" "Changelog-$file_device_name-*.md" || exit $?
    }
  
  # Re-enable Swap
  "$SCRIPT_DIR"/build-scripts/setupSwap.sh -e true || exit $?
}

# Show build rom GUI usage
_buildRomGUIUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: buildRomGUI [args]
#
# Sets up build environment, applies patches, builds rom, generates changelog, and uploads rom
buildRomGUI(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _buildRomGUI
  else
    while [[ $# -gt 0 ]]; do
      action="$1"
      case "$action" in
        -h|--help)
          shift
          _buildRomGUIUsage
          exit 0
         ;;
        *) log -e "Unknown arguments passed"; _buildRomGUIUsage; exit 128 ;;
      esac
    done
    _buildRomGUI
  fi
}

err_report() {
    local lineNo=$1
    local msg=$2
    echo "Error on line $lineNo: $msg"
    exit 1
}

trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./buildRomGUI.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && buildRomGUI "$@"
