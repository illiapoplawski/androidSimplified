#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: buildRom [OPTIONS]... [ARGUMENTS]...
#/ 
#/ OPTIONS  
#/   -h, --help
#/                Print this help message
#/   -t, --topdir <path>
#/                Specify Top Dir for Android source
#/   -o, --outdir <path/to/dir>
#/                Specify Output dir for Android build files
#/   -l, --locale [locale]
#/                Locale to set (no param resets locale)
#/   -c, --ccache <true|false>
#/                Automatically set ccache without dialog
#/   -d|--cachedir <path/to/ccache/dir>
#/                Set ccache directory
#/   --clearcache [true|false]
#/                Automatically clear CCache
#/   -s|--cachesize <size>
#/                Size of CCache in GB
#/   -n, --ninja <true|false>
#/                Set whether or not to use NINJA for compiling source
#/   -j, --jack <true | false>
#/                Use Jack for compiling source (only useful for android 6.0-8.1)
#/   --reset [true|false]
#/                Resets all projects
#/   --sync [true|false]
#/                Sync repo
#/   -p, --patchfile <path/to/file>
#/                Specify patch file with all patches to apply
#/   -g, --gerrit <gerrit url>
#/                Gerrit site to cherry pick from
#/   --verify [true|false]
#/                Verifies git status of all projects
#/   -rn, --romname <name>
#/                ROM Name to build
#/   -dn, --devicename <name>
#/                Device Name to build
#/   -sbt, --statixbuildtype <build type>
#/                Build types ( UNOFFICIAL | NUCLEAR | OFFICIAL )
#/   -bt, --buildtype <build type>
#/                Build Type to build ( user | userdebug | eng )
#/   -w, --clean <clean type>
#/                Clean types ( clean | installclean | none )
#/   -i, --image <image>
#/                Image type to build (boot | recovery | rom)
#/   --md5 [true|false]
#/                Generate MD5 for build image
#/   --changelog [true|false]
#/                Generate a changelog for build
#/   -cd, --changelogdays <int>
#/                Number of days for which to generate changelog
#/   --upload [true|false]
#/                Upload build
#/   -u, --uploaddir <path>
#/                Directory to upload build to
#/   -k, --archivecount <int>
#/                Number of files to keep in archive
#/
#/ EXAMPLES
#/   buildRom -h
#/   buildRom -t <path/to/top/dir>
#/   buildRom -t <path/to/top/dir> -o <out/dir> -l <locale> -c true -d <ccache/dir> -s <cache size> -n true -j false --reset --sync -p <path/to/file> -g <gerrit site> --verify -rn <rom name> -dn <device name> -sbt <statix build type> -bt <build type> -w <clean type> -i rom --md5 true --changelog -cd <days> --upload false -u <path/to/upload/dir> -k <archives to keep>
#/ 

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/utilities/logging.sh
. "$SCRIPT_DIR"/utilities/setTopDir.sh
. "$SCRIPT_DIR"/utilities/verifyPythonVenv.sh
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
. "$SCRIPT_DIR"/build-scripts/verifyRepopick.sh

# Usage: _buildRom
#
# Sets up build environment, applies patches, builds rom, generates changelog, and uploads rom
_buildRom() {
  # Disable Swap
  "$SCRIPT_DIR"/build-scripts/setupSwap.sh -e "false" || exit $?

  if [[ ! -v top_dir ]]; then
    log -e "Build top directory must be specified"
    exit 1
  fi

  # Set build top dir
  setTopDir -d "$top_dir" || exit $?

  if [[ ! -v out_dir ]]; then
    log -i "Setting out dir to top dir"
    out_dir="$BUILD_TOP_DIR"
  fi

  # Set out dir
  setOutDir -o "$out_dir" || exit $?

  # Enable Python 2.7 virtual environment
  verifyPythonVenv || exit $?

  # Setup build environment
  verifyRepopick || exit $?

  # Set locale
  setLocale -l "$locale" || exit $?

  # Setup ccache env variables
  setupCCache -d "$cache_dir" -c "$use_ccache" || exit $?

  if [[ "$clear_ccache" == "true" ]]; then
    # Clear ccache
    "$SCRIPT_DIR"/build-scripts/clearCCache.sh -c || exit $?
  fi

  # Set ccache size
  "$SCRIPT_DIR"/build-scripts/setCCacheSize.sh -s "$ccache_size_gb" || exit $?

  if [[ "$use_ninja" == "true" ]]; then
    # Setup Ninja
    setupNinja -n "$use_ninja" || exit $?
  fi

  if [[ "$use_jack" == "true" ]]; then
    # Setup Jack
    setupJack -e "$use_jack" || exit $?
  fi

  if [[ "$reset_projects" == "true" ]]; then
    # Reset projects
    "$SCRIPT_DIR"/build-scripts/resetProjects.sh --all --auto || exit $?
  fi

  if [[ "$sync_repo" == "true" ]]; then
    # Sync repo
    "$SCRIPT_DIR"/build-scripts/syncRepo.sh --auto || exit $?
  fi

  if [[ -v patch_file && -f $patch_file ]]; then
    local patch_dir
    local patch_file_name
    patch_dir=$(dirname "$patch_file")
    patch_file_name=${patch_file##*/}
    # Apply patches
    "$SCRIPT_DIR"/build-scripts/applyPatches.sh -l "$patch_dir" -p "$patch_file_name" -g "$gerrit_site" || exit $?
  else
    log -w "Not applying any patches"
  fi

  if [[ "$verify_git" == "true" ]]; then
    # Verify git status
    "$SCRIPT_DIR"/build-scripts/verifyGitStatus.sh --all --auto || exit $?
  fi

  # Set rom name
  setRomName -n "$rom_name" || exit $?

  # Set device name
  setDeviceName -n "$device_name" || exit $?

  # Set statix build type
  setStatixBuildType -t "$statix_build_type" || exit $?

  # Set build type
  setBuildType -t "$build_type" || exit $?

  # Set image type
  setImageType -t "$image_type" || exit $?

  local target
  target="${ROM_NAME}"_"${DEVICE_NAME}"-"${BUILD_TYPE}"

  unset IFS
  pushd "$BUILD_TOP_DIR/" &>/dev/null || exit $?
  log -i "Lunching target device"
  lunch "$target" || exit $?
  popd &>/dev/null || exit $?

  # Clean output
  "$SCRIPT_DIR"/build-scripts/cleanOutput.sh -c "$clean_type" || exit $?

  # Build image
  "$SCRIPT_DIR"/build-scripts/buildImage.sh || exit $?

  local file_name
  file_name=$(find "$ANDROID_PRODUCT_OUT" -maxdepth 1 -name "*_*-*.zip" -type f | sort | tail -1) || exit $?
  file_name=${file_name##*/}
  
  local file_device_name
  file_device_name=${file_name%%-*}

  if [[ "$generate_md5" == "true" ]]; then
    # Generate MD5
    "$SCRIPT_DIR"/build-scripts/generateMD5.sh -f "$ANDROID_PRODUCT_OUT"/"$file_name" || exit $?
  fi

  if [[ "$generate_changelog" == "true" ]]; then
    # Generate Changelog
    "$SCRIPT_DIR"/build-scripts/generateChangelog.sh -o "$ANDROID_PRODUCT_OUT" -n "$file_name" -c "$changelog_days" || exit $?
  fi

  if [[ "$upload_build" == "true" ]]; then
    # Set upload dir
    setUploadDir -d "$upload_dir" || exit $?

    # Archive old files
    "$SCRIPT_DIR"/build-scripts/archiveFile.sh -f "${UPLOAD_DIR}/*.*" -d "${UPLOAD_DIR}/Archive" || exit $?

    # Upload rom
    "$SCRIPT_DIR"/build-scripts/uploadFile.sh -f "$ANDROID_PRODUCT_OUT"/"$file_name" || exit $?

    # Delete old files
    "$SCRIPT_DIR"/build-scripts/deleteFiles.sh -d "$UPLOAD_DIR"/Archive -p "$file_device_name-*.zip" "$file_device_name-*.md5" "Changelog-$file_device_name-*.md" -k "$keep_count" || exit $?
  fi

  # Re-enable Swap
  "$SCRIPT_DIR"/build-scripts/setupSwap.sh -e "true" || exit $?
}

# Show build rom usage
_buildRomUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: buildRom [args]
#
# Sets up build environment, applies patches, builds rom, generates changelog, and uploads rom
buildRom(){
  local top_dir
  local out_dir
  local locale="C"
  local cache_dir="$HOME"
  local use_ccache="true"
  local clear_ccache="false"
  local ccache_size_gb="80"
  local use_ninja="true"
  local use_jack="false"
  local reset_projects="true"
  local sync_repo="true"
  local patch_file
  local gerrit_site="https://review.statixos.me/"
  local verify_git="true"
  local rom_name="statix"
  local device_name="angler"
  local statix_build_type="NUCLEAR"
  local build_type="userdebug"
  local clean_type="none"
  local image_type="rom"
  local generate_md5="true"
  local generate_changelog="true"
  local changelog_days="7"
  local upload_build="true"
  local upload_dir="$HOME/MEGA/StatiXOS"
  local keep_count="3"

  local action
  while [[ $# -gt 0 ]]; do
    action="$1"
    if [[ "$action" != '-'* ]]; then
      shift
      continue
    fi
    case "$action" in
      -h|--help)
        shift
        _buildRomUsage
        exit 0
        ;;
      -t|--topdir)
        local dir="$2"
        shift # past argument
        if [[ "$dir" != '-'* ]]; then
          shift # past value
          if [[ -n $dir && "$dir" != " " ]]; then
            top_dir="$dir"
          else 
            log -w "No base directory parameter specified"
          fi
        fi
        ;;
      -o|--outdir)
        local dir="$2"
        shift # past argument
        if [[ -n "$dir" && "$dir" != " " && "$dir" != '-'* ]]; then
          if [[ ! -d "$dir" ]]; then
            log -w "Invalid directory passed"
          else
            out_dir=$dir
          fi
          shift # past value
        else
          log -w "No output directory parameter specified"
        fi
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
      -d|--cachedir) 
        local dir="$2"
        shift # past argument
        if [[ "$dir" != '-'* ]]; then
          shift # past value
          if [[ -n $dir && "$dir" != " " ]]; then
            cache_dir="$dir"
          else 
            log -w "No ccache directory parameter specified"
          fi
        fi
        ;;
      -c|--ccache) 
        local value="$2"
        shift # past argument
        if [[ "$value" != '-'* ]]; then
          shift # past value
          if [[ -n $value && "$value" != " " ]]; then
            if [[ "$value" == "true" || "$value" == "false" ]]; then
              use_ccache="$value"
            else
              log -w "Unknown ccache arguments passed"
            fi
          else
            log -w "Empty use ccache parameter"
          fi
        else
          log -w "No use ccache parameter specified"
        fi
        ;;
      --clearcache)
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          clear_ccache="$val"
          shift # past value
        else
          clear_ccache="true"
        fi
        ;; 
      -s|--cachesize) 
        local size="$2"
        shift # past argument
        if [[ "$size" != '-'* ]]; then
          shift # past value
          if [[ -n $size && "$size" != " " ]]; then
            ccache_size_gb=$size
          else
            log -w "Empty ccache size parameter"
          fi
        else
          log -w "No ccache size parameter specified"
        fi
        ;;
      -n|--ninja) 
        local value="$2"
        shift # past argument
        if [[ "$value" != '-'* ]]; then
          shift # past value
          if [[ -n $value && "$value" != " " ]]; then
            if [[ "$value" == "true" || "$value" == "false" ]]; then
              use_ninja="$value"
            else
              log -e "Unknown ninja arguments passed"
            fi
          else
            log -w "Empty use ninja parameter"
          fi
        else
          log -w "No use ninja parameter specified"
        fi
        ;;
      -j|--jack) 
        local value="$2"
        shift # past argument
        if [[ "$value" != '-'* ]]; then
          shift # past value
          if [[ -n $value && "$value" != " " ]]; then
            if [[ "$value" = "true" || "$value" = "false" ]]; then
              use_jack="$value"
            else
              log -e "Unknown jack arguments passed"
            fi
          else
            log -w "Empty use jack parameter"
          fi
        else
          log -w "No use jack parameter specified"
        fi
        ;;
      --resetprojects) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          reset_projects="$val"
          shift # past value
        else
          reset_projects="true"
        fi
        ;;
      --sync) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          sync_repo="$val"
          shift # past value
        else
          sync_repo="true"
        fi
        ;;
      -p|--patchfile) 
        local name="$2"
        shift # past argument
        if [[ "$name" != '-'* ]]; then
          shift # past value
          if [[ -n $name && "$name" != " " ]]; then
            patch_file="$name"
          else
            log -w "Empty patch file parameter"
          fi
        else
          log -w "No patch file parameter specified"
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
      --verify) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          verify_git="$val"
          shift # past value
        else
          verify_git="true"
        fi
        ;;
      -rn|--romname)
        local nam="$2"
        shift # past argument
        if [[ "$nam" != '-'* ]]; then
          shift # past value
          if [[ -n $nam && "$nam" != " " ]]; then
            rom_name="$nam"
          else
            log -w "Empty rom name parameter"
          fi
        else
          log -w "No rom name parameter specified"
        fi
        ;;
      -dn|--devicename)
        local nam="$2"
        shift # past argument
        if [[ "$nam" != '-'* ]]; then
          shift # past value
          if [[ -n $nam && "$nam" != " " ]]; then
            device_name="$nam"
          else
            log -w "Empty device name parameter"
          fi
        else
          log -w "No device name parameter specified"
        fi
        ;;
      -sbt|--statixbuildtype)
        local typ="$2"
        shift # past argument
        if [[ "$typ" != '-'* ]]; then
          shift # past value
          if [[ -n $typ && "$typ" != " " ]]; then
            statix_build_type="$typ"
          else
            log -w "Empty statix build type parameter"
          fi
        else
          log -w "No statix build type parameter specified"
        fi
        ;;
      -bt|--buildtype)
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
      -w|--clean)
          local clean=$2
          shift # past argument
          if [[ "$clean" != '-'* ]]; then
            shift # past value
            if [[ -n $clean && "$clean" != " " ]]; then
              clean_type="$clean"
            else
              log -e "Empty clean type parameter"
              exit $?
            fi
          else
            log -w "No clean type parameter specified"
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
      --md5) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          generate_md5="$val"
          shift # past value
        else
          generate_md5="true"
        fi
        ;;
      --changelog) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          generate_changelog="$val"
          shift # past value
        else
          generate_changelog="true"
        fi
        ;;
      -cd|--changelogdays)
          local days="$2"
          shift # past argument
          if [[ "$days" != '-'* ]]; then
            shift # past value
            if [[ -n $days && "$days" != " " ]]; then
              changelog_days="$days"
            else
              log -w "Empty changelog days parameter"
            fi
          else
            log -w "No changelog days parameter specified"
          fi
          ;;
      --upload) 
        local val="$2"
        shift # past argument
        if [[ "$val" != '-'* ]]; then
          upload_build="$val"
          shift # past value
        else
          upload_build="true"
        fi
        ;;
      -u|--uploaddir)
        local dir="$2"
        shift # past argument
        if [[ "$dir" != '-'* ]]; then
          shift # past value
          if [[ -n $dir && "$dir" != " " ]]; then
            upload_dir="$dir"
          else 
            log -w "No upload directory parameter specified"
          fi
        fi
        ;;
      -k|--archivecount)
        local keep=$2
        shift # past argument
        if [[ "$keep" != '-'* ]]; then
          shift # past value
          if [[ -n $keep && "$keep" != " " ]]; then
            keep_count="$keep"
          else
            log -e "Empty keep parameter"
            exit $?
          fi
        else
          log -w "No keep parameter specified"
        fi
        ;;
      *) log -e "Unknown arguments passed"; _buildRomUsage; exit 128 ;;
    esac
  done
  _buildRom
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
  log -e "This script cannot be sourced. Use \"./buildRom.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && buildRom "$@"
