#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Displays the total number of virtual cpus in the system
#/
#/  Public Functions:
#/
#/ Usage: $totalCpu [OPTIONS]
#/
#/  OPTIONS: 
#/     -h, --help
#/                Print this help message
#/
#/  EXAMPLES:
#/     totalCpu
#/     totalCpu -h
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _totalCpu
#
# Returns the total number of cpus (including virtual)
_totalCpu() {
  local cpus
  cpus=$(getconf _NPROCESSORS_ONLN)
  #cpus="$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)"
  echo "$cpus"
}

# Show total CPU usage
_totalCpuUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: totalCpu [arg]
#
# Returns the total number of cpus including virtual cores
totalCpu(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _totalCpu
  else
    action="$1" && shift
    case "$action" in 
          -h|--help) _totalCpuUsage ;;
          *) log -e "Invalid argument"; _totalCpuUsage; exit 128 ;;
    esac
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./totalCpu.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && totalCpu "$@"
