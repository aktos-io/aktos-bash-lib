#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory
# $_sdir : this script's real file's directory

# show help
# -----------------------------------------------
show_help(){
    cat <<HELP

    $(basename $0) [options] /path/to/source /path/to/destination

    Options:

        --desc      : Description
        --foo       : Foo setting (required)

HELP
    exit
}

die(){
    echo
    echo_red "$1"
    show_help
    exit 1
}


# Parse command line arguments
# ---------------------------
# Initialize parameters
desc=
foo=
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
        --desc) shift
            desc="$1"
            shift
            ;;
        --foo) shift
            foo="$1"
            shift
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            echo
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)  # Generate the positional arguments: $_arg1, $_arg2, ...
            [[ ! -z ${1:-} ]] && declare _arg$((_count++))="$1" && shift
    esac
    [[ -z ${1:-} ]] && break
done; set -- "${args[@]}"
# use $_arg1 in place of $1, $_arg2 in place of $2 and so on, "$@" is intact

# Empty argument checking
# -----------------------------------------------
[[ -z ${foo:-} ]] && die "Foo can not be empty"

## For debugging of `this` file
echo "Foo is: $foo"

# All checks are done, run as root.
# NOTE: The double quotes around `$@` are very important for
# parsing arguments. 
[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }
