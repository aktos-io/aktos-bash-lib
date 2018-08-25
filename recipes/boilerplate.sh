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
    cat <<HELP

    $(basename $0) [options] /path/to/source /path/to/destination

    Options:

        --dry-run       : Dry run, don't touch anything actually

HELP
    exit
}

die(){
    echo_red "$1"
    show_help
    exit 1
}

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

# Parse command line arguments
# ---------------------------
# Initialize parameters
dry_run=false
new_hostname=
root_dir=
# ---------------------------
args=("$@")
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --dry-run) shift
            dry_run=true
            ;;
        --root-dir) shift
            if [[ ! -z ${1:-} ]]; then
                root_dir=$1
                shift
            fi
            ;;
        --hostname) shift
            new_hostname="$1"
            shift
            if [[ $new_hostname = "auto" ]]; then
                new_hostname=$(printf '0x%x' $(date +%s))
                new_hostname=${new_hostname/0x}
                echo "Automatically setting hostname to $new_hostname"
            fi
            ;;
        # --------------------------------------------------------
        --*)
            echo
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)  # generate the positional arguments: $_arg1, $_arg2, ...
            [[ ! -z ${1:-} ]] && declare _arg$((_count++))="$1" && shift
    esac
    [[ -z ${1:-} ]] && break
done; set -- "${args[@]}"
# use $_arg1 in place of $1, $_arg2 in place of $2 and so on, "$@" is intact

# All checks are done, run as root.
[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }
