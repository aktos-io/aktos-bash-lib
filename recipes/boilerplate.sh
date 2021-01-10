#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory
# $_sdir : this script's real file's directory

# source another bash file without changin the "magic" variables
safe_source /path/to/bash/file

# iterate over directory contents
for file in Data/*.txt; do
    [ -e "$file" ] || continue
    # ... rest of the loop body
done

# loop over command output
btrfs sub list / -R | while read -r sub; do
     #do work
    echo $sub
done

# or, if you want your loop to run in the same context:
while read -r sub; do
     #do work
    echo $sub
done <<< $(btrfs sub list / -R)

# Skip comment lines
while read -r line; do
  [[ $line = \#* ]] || [[ $line = "" ]] && continue # skip comment lines
  # do work here
done < /some/file.txt

# Extendable loop: https://superuser.com/q/1069702/187576
i=0
while :; do
    (("$i" >= "${#MODULES[@]}")) && break
    MODULE_NAME="${MODULES[$i]}"
    i=$((i+1))
    
    # ...
    if something-happens-only-one-time; then 
        MODULES+=( "e" )
    fi
    # ...
done 

# Array manipulation 
# -----------------------------------------------
# 
# see https://unix.stackexchange.com/a/395103/65781
# 
# -----------------------------------------------

# Implement dry-run option
# -----------------------------------------------
# then run any command with `check_dry_run` prefix
# check_dry_run btrfs sub snap / /path/to/snapshots
check_dry_run(){
    if [[ $dry_run = false ]]; then
        "$@"
    else
        echo "DRY RUN: $@"
    fi
}

# Check if array is empty (taken from: https://serverfault.com/a/477506/261445)
if [ ${#array[@]} -eq 0 ]; then
    echo "Empty"
else
    echo "Not empty"
fi

# Parse command line arguments
# see ./parse-arguments.sh

# All checks are done, run as root.
[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }

# Cleanup code (should be after "run as root")
# -----------------------------------------------
sure_exit(){
    echo
    echo_yellow "Interrupted by user."
    exit
}
cleanup(){
    echo "We are exiting."
    exit
}
trap sure_exit SIGINT # Runs on Ctrl+C, before EXIT
trap cleanup EXIT

# Conditional parameter adding
# -----------------------------------------------
_param=
[[ $new_keys = false ]] && _param="$_param --skip-ssh-keys"
/path/to/myprog --foo bar --baz qux $_param
