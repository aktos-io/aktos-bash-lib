pause () {
    PAUSE_MSG="$*"
    if [[ "$PAUSE_MSG" == "" ]]; then 
        PAUSE_MSG="Press Enter to continue..."
    fi
    read -p "$PAUSE_MSG"
}
