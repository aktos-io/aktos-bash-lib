pause () {
    PAUSE_MSG="$*"
    if [[ "$PAUSE_MSG" == "" ]]; then 
        PAUSE_MSG="Press Enter to continue..."
    fi
    read -p "$PAUSE_MSG"
}

SYMLINK_PATH=$(dirname $(readlink -f "$0"))

silent_run () {
    #echo "DEBUG: $*"

    # Run in background: 
    #nohup "$*" >/dev/null 2>&1 &
    # "Extra safe" version:
    nohup $* </dev/null >/dev/null 2>&1 &
}
