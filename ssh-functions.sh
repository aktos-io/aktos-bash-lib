SSH="ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o AddressFamily=inet"
SSHFS="sshfs -o reconnect,ServerAliveInterval=60,ServerAliveCountMax=3"


# Use credentials from global scope:
#
# * SSH_USER
# * SSH_HOST
# * SSH_PORT
# * SSH_KEY_FILE
# * SSH_PATH

[ ${SSH_SOCKET_FILE:-} ] || SSH_SOCKET_FILE="/tmp/ssh-${SSH_USER:-foo}@${SSH_HOST:-example.com}:${SSH_PORT:-22}.sock"

ssh_socket_run_cmd () {
    # SSH does not care the hostname while using socket file
    $SSH -S $SSH_SOCKET_FILE link-with-server $@
}

ssh_socket_make_forward () {
    ssh_socket_run_cmd -N $@
}


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

get_public_key () {
    local private_key=$1
    ssh-keygen -y -f $private_key
}

get_fingerprint () {
    local fingerprint_output
    if [[ -f "$1" ]]; then
        fingerprint_output=$(ssh-keygen -E md5 -l -f "$1")
    else
        fingerprint_output=$(ssh-keygen -E md5 -l -f <(echo "ssh-rsa $1"))
    fi
    if [[ "$fingerprint_output" != ""  ]]; then
        fingerprint_output=$(echo $fingerprint_output | cut -d ' ' -f 2)
        echo ${fingerprint_output#'MD5:'}
    fi
}

is_sshd_heartbeating () {
    local host=$1
    local port=$2
    local replay="$(echo | timeout 10 nc $host $port 2> /dev/null)"
    if [[ "$replay" != "" ]]; then
        return 0
    else
        return 1
    fi
}
