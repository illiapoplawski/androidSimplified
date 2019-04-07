#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Collection of memory functions to determine total ram in system
#/
#/  Public Functions:
#/
#/ Usage: $totalMem [OPTIONS]
#/
#/  OPTIONS: 
#/     -h, --help
#/                Print this help message
#/     -b, --bytes
#/                Displays total ram in bytes
#/     -b, --bytes
#/                Displays total ram in bytes
#/     -kb, --kilobytes
#/                Displays total ram in kilobytes
#/     -mb, --megabytes
#/                Displays total ram in megabytes
#/     -gb, --gigabytes
#/                Displays total ram in gigabytes
#/
#/  Default behaviour is to display total ram in kilobytes
#/
#/  EXAMPLES:
#/     totalMem
#/     totalMem -b
#/     totalMem -mb
#/     totalMem --gigabytes
#/

# don't hide errors within pipes
set -o pipefail

[[ -v SCRIPT_NAME ]]  || readonly SCRIPT_NAME="${BASH_SOURCE[0]}"
[[ -v SCRIPT_DIR ]]  || readonly SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_NAME" )" && pwd )"

IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

. "$SCRIPT_DIR"/logging.sh

# Usage: _totalMemoryKb
#
# Returns the total memory in KB
_totalMemoryKb() {
  local memKb
  memKb="$(getconf -a | grep PAGES | awk 'BEGIN {total = 1} {if (NR == 1 || NR == 3) total *=$NF} END {print total / 1024}')"
  #memKb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  echo "$memKb"
}

# Usage: _totalMemoryBytes
#
# Returns the total memory in Bytes
_totalMemoryBytes() {
  echo $(($(_totalMemoryKb) * 1024))
}

# Usage: _totalMemoryMb
#
# Returns the total memory in MB
_totalMemoryMb() {
  local memMbRaw
  local memMbAdjusted
  local memGbRounded
  memMbRaw=$(bc -l <<< "scale = 1; $(_totalMemoryKb) / 1024")
  memMbAdjusted=$(echo "$memMbRaw + 0.5" | bc) # Add 0.5 to raw decimal to round it to nearest integer
  memMbRounded=${memMbAdjusted%.*}
  echo "$memMbRounded"
}

# Usage: _totalMemoryGb
#
# Returns the total memory in GB
_totalMemoryGb() {
  local memGbRaw
  local memGbAdjusted
  local memGbRounded
  memGbRaw=$(bc -l <<< "scale = 1; $(_totalMemoryKb) / 1024 / 1024")
  memGbAdjusted=$(echo "$memGbRaw + 0.5" | bc) # Add 0.5 to raw value to round it to nearest integer
  memGbRounded=${memGbAdjusted%.*}
  echo "$memGbRounded"
}

# Show total mem usage
_totalMemUsage() {
  grep '^#/' "${SCRIPT_DIR}/${SCRIPT_NAME}" | sed 's/^#\/\w*//'
}

# Usage: totalMem [arg]
#
# Returns the total memory in the units specified
totalMem(){
  local action
  if [[ ${#} -eq 0 ]]; then
    _totalMemoryKb
  else
    action="$1" && shift
    case "$action" in 
          -h|--help) _totalMemUsage ;;
          -b|--bytes) _totalMemoryBytes ;;
          -kb|--kilobytes) _totalMemoryKb  ;;
          -mb|--megabytes) _totalMemoryMb ;;
          -gb|--gigabytes) _totalMemoryGb ;;
          *) log -e "Invalid argument"; _totalMemUsage; exit 128 ;;
    esac
  fi
}

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
  log -e "This script cannot be sourced. Use \"./totalMem.sh\" instead."
  return 1
fi

[[ "$0" == "${BASH_SOURCE[0]}" ]] && totalMem "$@"
