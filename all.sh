#!/bin/bash
set -eu -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

safe_source $_dir/basic-functions.sh
safe_source $_dir/btrfs-functions.sh
safe_source $_dir/fs-functions.sh
safe_source $_dir/luks-functions.sh
safe_source $_dir/ssh-functions.sh
