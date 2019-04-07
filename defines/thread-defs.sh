#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: source thread-defs.sh
#/ . thread-defs.sh
#/

# Color definitions
case $(uname -s) in
    Darwin) # Mac
        [[ -v THREADS ]] || readonly THREADS=$( sysctl -an hw.logicalcpu )
        ;;
    *)
        [[ -v THREADS ]] || readonly THREADS=$( grep -c processor /proc/cpuinfo )
        ;;
esac

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then 
  printf "${red:?}ERROR - %s${reset:?}\n" "This script must be sourced. Use \"source ./thread-defs.sh\" instead." 1>&2
  exit 1
fi
