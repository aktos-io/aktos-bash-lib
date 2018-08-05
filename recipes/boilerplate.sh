#!/bin/bash
set -eu -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate


# rest is the best practices
# ----------------------------------------------------

# variables
$_dir  # this script's directory 

# source another bash file 
safe_source /path/to/bash/file

# iterate over directory contents 
for file in Data/*.txt; do
    [ -e "$file" ] || continue
    # ... rest of the loop body
done

# All checks are done, run as root.
[[ $(whoami) = "root" ]] || { sudo $0 $*; exit 0; }


# loop over command output
btrfs sub list / -R | while read -r sub; do
     #do work
    echo $sub
done   

