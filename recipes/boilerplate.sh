#!/bin/bash
set -eu -o pipefail 
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory 
# $_sdir : this script's real file's directory

# source another bash file without changin the "magic" variables
safe_source /path/to/bash/file

# All checks are done, run as root.
[[ $(whoami) = "root" ]] || { sudo $0 $*; exit 0; }

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
