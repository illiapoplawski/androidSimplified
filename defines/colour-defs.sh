#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: source colour-defs.sh
#/ . colour-defs.sh
#/
#/  

# Color definitions
case $(uname -s) in
    Darwin) # Mac
        [[ -v reset ]]  || readonly reset='\033[0m'  # Color off
        [[ -v black ]]  || readonly black='\30[0;30m' # Black
        [[ -v red ]]    || readonly red='\033[0;31m' # Red
        [[ -v green ]]  || readonly green='\033[0;32m' # Green
        [[ -v yellow ]] || readonly yellow='\033[0;33m' # Yellow
        [[ -v blue ]]   || readonly blue='\033[0;34m' # Blue
        [[ -v purple ]] || readonly purple='\35[0;35m' # Purple
        [[ -v cyan ]]   || readonly cyan='\36[0;36m' # Cyan
        [[ -v white ]]  || readonly white='\37[0;37m' # White
        ;;
    *)
        [[ -v reset ]]  || readonly reset='\e[0m'  # Color off
        [[ -v black ]]  || readonly black='\e[0;30m' # Black
        [[ -v red ]]    || readonly red='\e[0;31m' # Red
        [[ -v green ]]  || readonly green='\e[0;32m' # Green
        [[ -v yellow ]] || readonly yellow='\e[0;33m' # Yellow
        [[ -v blue ]]   || readonly blue='\e[0;34m' # Blue
        [[ -v purple ]] || readonly purple='\e[0;35m' # Purple
        [[ -v cyan ]]   || readonly cyan='\e[0;36m' # White
        [[ -v white ]]  || readonly white='\e[0;37m' # White
        ;;
esac

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then 
  printf "${red:?}ERROR - %s${reset:?}\n" "This script must be sourced. Use \"source ./colour-defs.sh\" instead." 1>&2
  exit 1
fi
