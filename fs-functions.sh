get_free_space_of_snap () {
    # returns in KBytes
    local snap=$1
    #echo_info "Calculating free space of $(mount_point_of $snap)"
    df -k --output=avail $snap | sed '2q;d'
}

get_relative(){
    current="$1"
    absolute="$2"
    echo $(perl -MFile::Spec -e 'print File::Spec->abs2rel("'$absolute'","'$current'")')
}
# Example: get relative path according to $PWD:
# relative=$(get_relative $PWD $mypath)

is_free_space_more_than () {
    local target_size_str=$1
    local target_size=$(echo $target_size_str | numfmt --from=si)
    target_size=$(( $target_size / 1000 ))
    local snap=$2
    local curr_size=$(get_free_space_of_snap $snap)

    echo_debug "target_size: $target_size ($target_size_str), curr_size: $curr_size"
    if (( "$curr_size" >= "$target_size" )); then
        echo_debug "Free space is enough."
        return 0
    else
        echo_debug "Free space is NOT enough..."
        return 1
    fi
}

mount_point_of () {
    local file=$1
    [[ -e $file ]] || echo_err "No such file found: $file"
    findmnt -n -o TARGET --target $file
}

umount_if_mounted () {
    local device=$1
    set +u
    local flag=$2
    set -u
    echo "unmounting device: $device"
    # DO NOT USE `grep DEVICE /proc/mounts` since one device might be represented
    # more than one form (such as LVM parts)
    set +e
    umount $flag $device 2> /dev/null
    set -e
}

require_not_mounted () {
    local target=$1
    set +e
    mount | grep $target > /dev/null
    local ret=$?
    set -e
    if [ $ret == 0 ]; then
        echo_err "$target IS NOT EXPECTED TO BE MOUNTED!"
    fi
}

require_mounted () {
	if ! mountpoint $1 > /dev/null 2>&1; then
		echo_err "$1 is not a mountpoint, mount first!"
	fi
}

mount_unless_mounted () {
    # mount_if_not_mounted DEVICE MOUNT_POINT
    set +o errexit +o pipefail
    grep -qs $2 /proc/mounts 2> /dev/null
    local is_mounted=$?
    set -o errexit -o pipefail
    [ $is_mounted -ne 0 ] && mount -v "$1" "$2"
}

get_device_by_id () {
    require_device $(readlink -f /dev/disk/by-id/$1)
}

get_device_by_uuid () {
    require_device $(readlink -f /dev/disk/by-uuid/$1)
}

require_device () {
    local device=$1
    if [ -b $device ]; then
        echo $device
    else
        echo_err "No such partition/device can be found: $device"
        exit 1
    fi
}

require_different_disks () {
    if [[ $(mount_point_of $1) = $(mount_point_of $2) ]]; then
        echo_err "Source and destination are on the same disk!"
    fi
}

exec_limited () {
	cpulimit -l 30 -f -q -- $*
	return $?
}

# Query related
get-latest-folder(){
    # Taken from https://stackoverflow.com/a/26766782/1952991
    #
    # Use ${1-} instead of $1 in case 'nounset' is set
    local -r glob_pattern=${1-}

    if (( $# != 1 )) ; then
        echo 'usage: newest_matching_file GLOB_PATTERN' >&2
        return 1
    fi

    # To avoid printing garbage if no files match the pattern, set
    # 'nullglob' if necessary
    local -i need_to_unset_nullglob=0
    if [[ ":$BASHOPTS:" != *:nullglob:* ]] ; then
        shopt -s nullglob
        need_to_unset_nullglob=1
    fi

    newest_file=
    for file in $glob_pattern/* ; do
        newest_file=$file
    done

    # To avoid unexpected behaviour elsewhere, unset nullglob if it was
    # set by this function
    (( need_to_unset_nullglob )) && shopt -u nullglob

    # Use printf instead of echo in case the file name begins with '-'
    [[ -n $newest_file ]] && printf '%s\n' "$newest_file"

    return 0
}



# Physical disk related
find_disks () {
    fdisk -l 2>/dev/null \
        | grep "Disk \/" \
        | grep -v "\/dev\/md" \
        | grep -v "\/dev\/mapper" \
        | awk '{print $2}' | sed -e 's/://g'
}

# LVM functions
#--------------
detach_lvm_parts(){
    local lvm_prefix=$1
    for part in ${lvm_prefix}-*; do
        [ -e "$part" ] || continue
        echo "...detaching $part"
        lvchange -a n $part
    done
}

attach_lvm_parts(){
    echo "TO BE IMPLEMENTED"
}
