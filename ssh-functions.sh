parse_url () {
    local section=$1
    local full_url=$2
    # extract the protocol
    proto_full="$(echo $full_url | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    proto="$(echo ${proto_full/'://'})"
    # remove the protocol
    url="$(echo ${full_url/$proto_full/})"
    # extract the user (if any)
    user="$(echo $url | grep @ | cut -d@ -f1)"
    # extract the host
    host="$(echo ${url/$user@/} | cut -d/ -f1)"
    # by request - try to extract the port
    port="$(echo $host | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    only_host="$(echo ${host/":$port"/})"
    # extract the path (if any)
    path="/$(echo $url | grep / | cut -d/ -f2-)"

    case "$section" in
            url)
                echo $url
                ;;
            protocol)
                echo $proto
                ;;
            user)
                echo $user
                ;;
            host)
                echo $only_host
                ;;
            port)
                echo $port
                ;;
            path)
                echo $path
                ;;
            *)
                echo "url:$url"
                echo "protocol:$proto"
                echo "user:$user"
                echo "host:$only_host"
                echo "port:$port"
                echo "path:$path"
    esac
}
