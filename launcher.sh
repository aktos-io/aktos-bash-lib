silent_run () {
    #echo "DEBUG: $*"

    # Run in background:
    #nohup "$*" >/dev/null 2>&1 &
    # "Extra safe" version:
    nohup $* </dev/null >/dev/null 2>&1 &
}
