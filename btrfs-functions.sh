take_snapshot () {
    local src=$1
    local dest=$2
    btrfs sub snap -r "$src" "$dest"
}

get_btrfs_received_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "Received UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

get_btrfs_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "^\s*UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

get_btrfs_parent_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "Parent UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

is_subvolume_incomplete () {
    local subvol=$1
    if [[ "$(get_btrfs_received_uuid $subvol)" == "" ]]; then
        echo_debug "$subvol is incomplete"
        return 0
    else
        echo_debug "$subvol is complete"
        return 1
    fi
}

is_subvolume_readonly () {
    local subvol=$1
    local readonly_flag="$(btrfs property get $subvol ro | grep ro= | awk -F= '{print $2}')"
    if [[ "$readonly_flag" == "true" ]]; then
        # yes, it is readonly
        return 0
    elif [[ "$readonly_flag" == "false" ]]; then
        # no, it is writable
        return 1
    else
        echo_err "${FUNCNAME[0]} can not determine if subvol is readonly or not!"
    fi
}

# Check if target has btrfs filesystem
# taken from https://github.com/lxc/lxc/blob/master/templates/lxc-debian.in
is_btrfs(){
    [ -e "$1" -a "$(stat -f -c '%T' "$1")" = "btrfs" ]
}

# Check if given path is the root of a btrfs subvolume
# taken from https://github.com/lxc/lxc/blob/master/templates/lxc-debian.in
is_btrfs_subvolume(){
    [[ -d "$1" ]] && [[ "$(stat -f -c '%T' "$1")" = "btrfs" ]] && [[ "$(stat -c '%i' "$1")" -eq 256 ]]
}

get_subvol_list(){
    btrfs sub list -R -u -r "$1"
}

find_sent_subs(){
    # -------------------------------------
    # FIXME: while inside while is TOO SLOW
    # -------------------------------------
    local s=$(echo $1 | sed 's/\/*$//g')  # source
    local d=$(echo $2 | sed 's/\/*$//g')  # destination
    local s_mnt=$(mount_point_of $s)
    local d_mnt=$(mount_point_of $d)
    local s_subvols=$(get_subvol_list $s_mnt)
    local d_subvols=$(get_subvol_list $d_mnt)
    while read -r ssub; do
        s_rcv=`echo $ssub | get_line_field received_uuid`
        s_id=`echo $ssub | get_line_field uuid`
        s_path=`echo $ssub | get_line_field path`
        while read -r dsub; do
            d_rcv=`echo $dsub | get_line_field received_uuid`
            d_id=`echo $dsub | get_line_field uuid`
            d_path=`echo $dsub | get_line_field path`
            if [[ $s_rcv = $d_rcv ]] || [[ $s_id = $d_rcv ]]; then
                # match found
                src_subvol="$s_mnt/$s_path"
                dst_subvol="$d_mnt/$d_path"

                # print if subvolume is below the source path
                if [[ $src_subvol = $s/* ]]; then
                    echo $src_subvol
                fi
                break
            fi
        done <<< "$d_subvols"
    done <<< "$s_subvols"
}

list_subvol_below () {
    local path=$(echo $1 | sed 's/\/*$//g')
    local include_rw=
    if [[ ${2:-} = true ]]; then
        #errcho "Including rw snapshots"
        include_rw=
    else
        include_rw="-r"
    fi
    local mnt=$(mount_point_of $path)
    local rel_path=${path#$mnt/}
    #errcho "list_subvol_below: mnt is $mnt rel_path is $rel_path"
    btrfs sub list $include_rw $mnt | get_line_field 'path' | while read -r sub; do
        if [[ $sub = $rel_path/* ]]; then
            echo $mnt/$sub
        fi
    done
}

get_snapshot_roots(){
    # finds incrementally snapshotted subvolume paths
    local dirs=`list_subvol_below $1 | xargs dirname | sort | uniq`
    local excludes=()
    for i in $dirs; do
        for j in $dirs; do
            if [[ $j = $i/* ]]; then
                # $i is parent, so should be removed from output
                excludes+=( $i )
                break
            fi
        done
    done
    for out in $dirs; do
        if containsElement $out "${excludes[@]}"; then
            continue
        fi
        echo $out
    done
}

find_missing_subs(){
    local src=$1
    local dst=$2
    comm -23 <( list_subvol_below $src ) <( find_sent_subs $src $dst )
}

find_prev_snap(){
    local target="${1}"
    shift
    local list=("${@}")
    local match=
    for i in "${list[@]}"; do
        if [[ $target = $i ]]; then
            break
        fi
        match=$i
        #echo "searching $target if matches with $i"
    done
    echo $match
}
