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
