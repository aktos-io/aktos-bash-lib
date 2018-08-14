#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

safe_source $_dir/basic-functions.sh
safe_source $_dir/btrfs-functions.sh
safe_source $_dir/fs-functions.sh
safe_source $_dir/luks-functions.sh
safe_source $_dir/ssh-functions.sh
