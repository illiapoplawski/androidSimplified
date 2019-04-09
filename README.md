# androidSimplified
Collection of scripts to simplify setting up an android build environment, syncing a repository, and building the source

All scripts can be run with a GUI or passed arguments to run automatically without user input.

Run the scripts in the following order to setup your environment and build the rom
# GUI Mode
1) setupBuildEnvGUI.sh
2) setupRomRepoGUI.sh
3) buildRomGUI.sh

# Auto Mode*
1) setupBuildEnv.sh
2) setupRomRepo.sh -d <path/to/root/dir>
3) buildRom.sh -t <path/to/root/dir> -p <path/to/patch/file**>
* Rather than pass custom parameters each time, the defaults can be set in the scripts and then the commands can be run with no arguments.
** If the patch file argument is not set then no patches will be applied.

Each script in any folder that is executable can take the <-h> argument to see the functionality of the individual script.

For scripts that must be sourced, run "source script.sh" then run scriptname.sh -h to see the help menu for the script.

Every script is designed to be able to be run individually so feel free to look through the scripts to see what may be useful to you in different situations.
