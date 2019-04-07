#! /usr/bin/env bash
#
# Author: Illia Poplawski <illia.poplawski@gmail.com>
#
#/ Usage: source colour-defs.sh
#/ . colour-defs.sh
#/
#/ 
#/ Possible Colour Definitions
#/ name=[fg],[bg][;|:|\n|\r|\t]name2=[fg],[bg]]...
#/ 
#/ name can be:
#/ 
#/ root                  root fg, bg
#/ border                border fg, bg
#/ window                window fg, bg
#/ shadow                shadow fg, bg
#/ title                 title fg, bg
#/ button                button fg, bg
#/ actbutton             active button fg, bg
#/ checkbox              checkbox fg, bg
#/ actcheckbox           active checkbox fg, bg
#/ entry                 entry box fg, bg
#/ label                 label fg, bg
#/ listbox               listbox fg, bg
#/ actlistbox            active listbox fg, bg
#/ textbox               textbox fg, bg
#/ acttextbox            active textbox fg, bg
#/ helpline              help line
#/ roottext              root text
#/ emptyscale            scale full
#/ fullscale             scale empty
#/ disentry              disabled entry fg, bg
#/ compactbutton         compact button fg, bg
#/ actsellistbox         active & sel listbox
#/ sellistbox            selected listbox
#/ 
#/ bg and fg can be:
#/ 
#/ color0  or black
#/ color1  or red
#/ color2  or green
#/ color3  or brown
#/ color4  or blue
#/ color5  or magenta
#/ color6  or cyan
#/ color7  or lightgray
#/ color8  or gray
#/ color9  or brightred
#/ color10 or brightgreen
#/ color11 or yellow
#/ color12 or brightblue
#/ color13 or brightmagenta
#/ color14 or brightcyan
#/ color15 or white

export NEWT_COLORS='
  root=white,black
  border=black,lightgray
  window=lightgray,lightgray
  shadow=black,gray

  title=black,lightgray

  button=black,cyan
  actbutton=white,cyan
  compactbutton=black,lightgray

  checkbox=black,lightgray
  actcheckbox=lightgray,cyan

  entry=black,lightgray
  disentry=gray,lightgray

  label=black,lightgray

  listbox=black,lightgray
  actlistbox=black,cyan
  sellistbox=lightgray,black
  actsellistbox=lightgray,black

  textbox=black,lightgray
  acttextbox=black,cyan

  emptyscale=,gray
  fullscale=,cyan

  helpline=white,black
  roottext=lightgrey,black
'

(return 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then 
  printf "${red:?}ERROR - %s${reset:?}\n" "This script must be sourced. Use \"source ./whiptail-defs.sh\" instead." 1>&2
  exit 1
fi
