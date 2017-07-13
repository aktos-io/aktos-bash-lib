#!/bin/bash

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

SYMLINK_PATH=$(dirname $(readlink -f "$0"))


#safe_source $DIR/../common.sh
#safe_source $DIR/config.sh
