is_network_reachable() {
    # returns: boolean
    /bin/ping -c1 -w1 8.8.8.8 &> /dev/null
}

get_ip_of(){
    # returns: string
    local iface=$1
    ifconfig $iface | egrep "inet\W" | awk '{print $2}'
}

is_cable_plugged() {
    # returns: boolean
    # true if cable is plugged, else false
    local iface=$1
    [[ `ifconfig $iface | sed -n '/running/I p'` != '' ]]
}


is_ip_reachable(){
    # returns: boolean
    local ip="$1"
    local failed_before=false
    local timeout=${2:-"00:00:30"}
    local timeout_sec=`echo $timeout | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }'`
    local start_date=`date +%s`
    while :; do
        # FIXME: https://superuser.com/q/1446588/187576
        if timeout 9s ping -c 1 "$ip" &> /dev/null; then
            # immediately return if succeeded
            if $failed_before; then
                echo_stamp "successfully ping to $ip"
            fi
            return 0
        else
            failed_before=true
            echo_stamp "trying to get a successful ping to $ip"
        fi
        if [[ $(($start_date + $timeout_sec - `date +%s`)) -lt 0 ]]; then
            break
        fi
    done
    echo_stamp "timed out."
    return 2
}
