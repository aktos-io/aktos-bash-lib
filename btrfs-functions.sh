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

get_snapshot_in_dest () {
    # DEPRECATED??



    # get_snapshot_in_dest snapshot remote_folder
    local src=$1
    local dest=$2
    local snap_found=""
    if [[ "$2" == "" ]]; then
        echo_err "Usage: ${FUNCNAME[0]} src dest"
    fi

    #DEBUG=true


    #echo_debug "${FUNCNAME[0]}: src: $src, dest: $dest"
    # if $dest_snap's received_uuid is the same as $src_snap's uuid, then
    # it means that these snapshots are identical.
    local dest_mount_point=$(mount_point_of $dest)
    local uuid_of_src="$(get_btrfs_uuid $src)"
    local snap_already_sent=""

    echo_debug "uuid_of_src: $uuid_of_src"
    echo_debug "dest_mount_point: $dest_mount_point"

    if [[ ! -z $uuid_of_src ]]; then
        snap_already_sent=$(btrfs sub list -R $dest_mount_point | grep $uuid_of_src )
        echo_debug "snap already sent (raw): $snap_already_sent"

        if [[ "$snap_already_sent" != "" ]]; then
            snap_found="$dest_mount_point/$(echo $snap_already_sent | get_line_field 'path')"
            echo "$(readlink -m $snap_found)"
            return 0
        fi
    fi

    # try the reverse
    local received_uuid_of_local="$(get_btrfs_received_uuid $src)"
    if [[ ! -z $received_uuid_of_local ]]; then
        dest_mount_point=$(mount_point_of $dest)
        snap_already_sent=$(btrfs sub list -u $dest_mount_point | grep "$received_uuid_of_local" )

        echo_debug "received_uuid_of_local: $received_uuid_of_local"
        echo_debug "dest_mount_point: $dest_mount_point"
        echo_debug "snap already sent (raw): $snap_already_sent"

        if [[ "$snap_already_sent" != "" ]]; then
            snap_found="$dest_mount_point/$(echo $snap_already_sent | get_line_field 'path')"
            echo "$(readlink -m  $snap_found)"
            return 0
        fi
    fi
}

last_snapshot_in () {
    local TARGET=$1
    snapshots_in $TARGET | tail -n 1
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

# taken from https://github.com/lxc/lxc/blob/master/templates/lxc-debian.in
is_btrfs(){
    [ -e "$1" -a "$(stat -f -c '%T' "$1")" = "btrfs" ]
}

# Check if given path is the root of a btrfs subvolume
is_btrfs_subvolume(){
    [ -d "$1" -a "$(stat -f -c '%T' "$1")" = "btrfs" -a "$(stat -c '%i' "$1")" -eq 256 ]
}
# end of https://github.com/lxc/lxc/blob/master/templates/lxc-debian.in

snapshots_in () {
    # usage: FUNC [options] directory
    # --all         : list all subvolumes, not only readonly ones
    # --incomplete  : list only incomplete snapshots ()
    local list_only_readonly=true
    local list_only_incomplete=false
    local TARGET=$1
    if [[ "$1" == "--all" ]]; then
        TARGET=$2
        list_only_readonly=false
    elif [[ "$1" == "--incomplete" ]]; then
        TARGET=$2
        list_only_readonly=false
        list_only_incomplete=true
    fi

    while read -a snap; do
        if is_btrfs_subvolume $snap; then
            if $list_only_readonly; then
                if is_subvolume_readonly $snap; then
                    echo $snap
                fi
            else
                if $list_only_incomplete; then
                    if is_subvolume_incomplete $snap; then
                        echo $snap
                    fi
                else
                    echo $snap
                fi
            fi
        fi
    done < <( find $TARGET/ -maxdepth 1 -mindepth 1 )
}

require_being_btrfs_subvolume () {
    local subvol=$1
    if ! is_btrfs_subvolume $subvol; then
    	echo_err "$subvol not found, create it first."
    fi
}

require_different_disks () {
    if [[ $(mount_point_of $1) = $(mount_point_of $2) ]]; then
        echo_err "Source and destination are on the same disk!"
    fi
}

get_subvol_list(){
    btrfs sub list -R -u -r "$1"
}
find_sent_subs(){
    local s=$1  # source
    local d=$2  # destination
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
            fi
        done <<< "$d_subvols"
    done <<< "$s_subvols"
}
list_subvol_below () {
    local path=$1
    local include_rw=
    if [[ ${2:-} = true ]]; then
        #errcho "Including rw snapshots"
        include_rw=
    else
        include_rw="-r"
    fi
    local mnt=$(mount_point_of $path)
    local rel_path=${path#$mnt/}
    #errcho "list_subvol_below: mnt is $mnt"
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
