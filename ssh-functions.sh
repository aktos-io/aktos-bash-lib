SSH="ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3"
SSHFS="sshfs -o reconnect,ServerAliveInterval=60,ServerAliveCountMax=3"

# Use credentials from global scope:
#
# * SSH_USER
# * SSH_HOST
# * SSH_PORT
# * SSH_KEY_FILE
# * SSH_PATH

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


check_ssh_key () {
    $SSH -o PasswordAuthentication=no $SSH_USER@$SSH_HOST -p $SSH_PORT -i $SSH_KEY_FILE exit 0 2> /dev/null
}

ssh_passwd_command () {
    local params=$@
    $SSH $SSH_USER@$SSH_HOST -p $SSH_PORT $params
}

ssh_id_command() {
    local params=$@
    $SSH -t $SSH_USER@$SSH_HOST -p $SSH_PORT -i $SSH_KEY_FILE $params
}

ssh_socket_command () {
    echo "..."
}

get_public_key () {
    local private_key=$1
    ssh-keygen -y -f $private_key
}
