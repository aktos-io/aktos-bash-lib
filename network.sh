is_network_reachable() {
   /bin/ping -c1 -w1 8.8.8.8 &> /dev/null
}

get_ip_of(){
    local iface=$1
    ifconfig $iface | egrep "inet\W" | awk '{print $2}'
}
