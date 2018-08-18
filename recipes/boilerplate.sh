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
done <<< `btrfs sub list / -R`

# show help
show_help(){
    local script=$(basename $0)
    local reason=${1:-}
    [[ ! -z $reason ]] && cat <<REASON
    -------------------------------
    ERROR: $reason
    -------------------------------
REASON
    cat <<HELP

    $script [options] /path/to/source /path/to/destination

    Options:

        --dry-run       : Dry run, don't touch anything actually

HELP
    exit
}


# parsing command line arguments 
POSITIONAL=()
_count=1
while :; do
    POSITIONAL+=("${1:-}") # save for "sudo $0" usage
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        --dry-run)       # Takes an option argument; ensure it has been specified.
            shift
            dry_run=true
            ;;
        *)  # save the positional arguments
            declare _arg$((_count++))="$1"
            shift
    esac
    [[ -z ${1:-} ]] && break
done
set -- "${POSITIONAL[@]}"
# use $_arg1 in place of $1, $_arg2 in place of $2 and so on, "$@" is intact

# All checks are done, run as root.
[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }
