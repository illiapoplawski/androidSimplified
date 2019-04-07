#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Sets up Jack
#/
#/  Public Functions:
#/
#/ Usage: setupJack [OPTIONS]...
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message
#/   -d, --directory <path/to/dir>
#/                Specify Top Dir for Android source
#/   -e, --enable <true | false>
#/                Use Jack for compiling source
#/
#/ EXAMPLES
#/   setupJack
#/   setupJack -d <path/to/root/dir> -e false
#/

# Ensures script is only sourced once
if [[ ${SETUP_JACK_GUARD:-} -eq 1 ]]; then
  return
else
  readonly SETUP_JACK_GUARD=1
fi

# don't hide errors within pipes
set -o pipefail

[[ -v SETUP_JACK_SCRIPT_NAME ]]  || readonly SETUP_JACK_SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SETUP_JACK_SCRIPT_DIR ]]  || readonly SETUP_JACK_SCRIPT_DIR="$( cd "$( dirname "$SETUP_JACK_SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/logging.sh
. "$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/setTopDir.sh

# Usage: _setupJack
#
# Sets up Jack
_setupJack() {
  local total_mem
  # https://source.android.com/setup/build/jack
  if [[ ! -v enableJack ]]; then
    "$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/userFunctions.sh getYesNo -t "Enable Jack" -d "Would you like to use Jack Server to compile the source code?\n -Only use Jack when compiling Android between 6.0 and 8.1" -i "no" || {
      log -i "Not using Jack Server"
      return 0
    }
  fi

  log -i "User chose to use Jack.  Checking if Jack is necesssary."
    
  if [[ ! -v BUILD_TOP_DIR ]]; then
    # Set top dir
    setTopDir || exit $?
  fi

  total_mem=$("$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/totalMem.sh -gb)
  if [[ $total_mem -lt 16 ]]; then
    log -i "Machine has less than 16GB of RAM.  Configuring Java maximum heap size"
    # Setup JACK VM args to use half of total RAM
    local reducedRam
    reducedRam=$("$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/scaleMem.sh -m "$("$(dirname "$SETUP_JACK_SCRIPT_DIR")"/utilities/totalMem.sh -gb)" -s "0.5")
    log -i "set heap to: $reducedRam"
    ANDROID_JACK_VM_ARGS="-Xms${reducedRam}g -Xmx${reducedRam}g -XX:+TieredCompilation -Dfile.encoding=UTF-8"
    export ANDROID_JACK_VM_ARGS
  else
    log -i "Machine has enough RAM.  Not using custom heap size"
  fi

  # Kill JACK Server
  log -i "Stopping Jack Server"
  "$BUILD_TOP_DIR"/prebuilts/sdk/tools/jack-admin kill-server

  #Clear old Jack Files
  log -i "Clearing old files"
  rm -rf ~/.jack*

  # Install Jack Server
  log -i "Installing latest Jack Server"
  "$BUILD_TOP_DIR"/prebuilts/sdk/tools/jack-admin install-server "$BUILD_TOP_DIR"/prebuilts/sdk/tools/jack-launcher.jar "$BUILD_TOP_DIR"/prebuilts/sdk/tools/jack-server-*.jar

  local max_servers
  max_servers=$(( total_mem / 4))
  if [[ $max_servers -le 0 ]]; then
      max_servers=1
  fi
  mkdir -p ~/.jack-server
  echo "jack.server.max-service=$max_servers" >> ~/.jack-server/config.properties
  chmod 600 ~/.jack-server/config.properties
  
  # Start Jack Server
  log -i "Starting Jack Server"
  "$BUILD_TOP_DIR"/prebuilts/sdk/tools/jack-admin start-server
}

# Show setup jack usage info
_setupJackUsage() {
  grep '^#/' "${SETUP_JACK_SCRIPT_DIR}/${SETUP_JACK_SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: setupNinja [arg]
#
# Sets up Jack for building AOSP
setupJack(){
  local enableJack

  local action
  if [[ ${#} -eq 0 ]]; then
    _setupJack
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
          _setupJackUsage
          return 0
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
        -e|--enable) 
          local value="$2"
          shift # past argument
          if [[ "$value" != '-'* ]]; then
            shift # past value
            if [[ -n $value && "$value" != " " ]]; then
              if [[ "$value" = "true" || "$value" = "false" ]]; then
                enableJack="$value"
              else
                log -e "Unknown arguments passed"; _setupJackUsage; return 128
              fi
            else
              log -w "Empty use jack parameter"
            fi
          else
            log -w "No use jack parameter specified"
          fi
          ;;
        *) 
          log -w "Unknown argument passed: $action. Skipping"
          shift # past argument
          ;;
      esac
    done
    _setupJack
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  log -e "This script must be sourced. Use \"source ./setupJack.sh\" instead."
  exit 1
fi