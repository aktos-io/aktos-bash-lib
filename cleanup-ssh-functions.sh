
# ------------------------- LIBRARY FUNCTIONS ----------------------------------- #
#SSH_COMMON="-F /dev/null -o ServerAliveCountMax=5 -o ServerAliveInterval=3 -o ConnectTimeout=10 -o ConnectionAttempts=2 -o BatchMode=yes"
SSH_COMMON="-o AddressFamily=inet"
#SSH_RCE_COMMON="-f -N -o PreferredAuthentications=publickey, " # Common options for Remote Command Execution

run_ssh_command(){
  local REMOTE_COMMAND="$*"
  local SSH_COMMAND=""

  local SOCKET=$(printf "%q" "$MOBMAC_SSH_SOCKET_TO_USE")

  ls "$SOCKET" &> /dev/null
  if [[ $? -eq 0 ]]; then
    # there is the socket to use, use it
    SSH_COMMAND="ssh -o PreferredAuthentications=, $SSH_COMMON -S "$SOCKET" $PROXY_HOST $REMOTE_COMMAND"
  else
    #SSH_COMMAND="ssh -o PreferredAuthentications=publickey, -i "$SSH_ID_FILE" $PROXY_USERNAME@$PROXY_HOST -p $PROXY_SSHD_PORT $REMOTE_COMMAND"
    ccalog "SSH SOCKET FILE NOT FOUND: $SOCKET"
    exit 1
  fi
  ccalog "SSH_COMMAND: $SSH_COMMAND"
  local OUTPUT
  OUTPUT=$(eval '$SSH_COMMAND') # MINIMUM 10 SECONDS
  if [[ $? -ne 0 ]]; then
    ccalog "ERROR ON EXECUTING SSH COMMAND"
    rm_ssh_socket
  else
    ccalog "COMMAND EXECUTED NORMALLY..."
    echo $OUTPUT
  fi
}

rm_ssh_socket() {
  local SOCKET=$(printf "%q" "$MOBMAC_SSH_SOCKET_TO_USE")

  ccalog "Removing ssh socket: $SOCKET"
  rm "$SOCKET" &> /dev/null
}

create_ssh_socket() {
    ls $MOBMAC_SSH_SOCKET_TO_USE &> /dev/null
    if [[ $? -eq 0 ]]; then
      echolog "SSH socket already exists."
    else
      echolog "Creating new SSH socket."
      ssh -i "$SSH_ID_FILE" $SSH_COMMON -o PreferredAuthentications=publickey, -f -N \
	-M -S $MONITOR_SOCKET_ON_MOBMAC -o ExitOnForwardFailure=yes  \
	$PROXY_USERNAME@$PROXY_HOST -p $PROXY_SSHD_PORT
    fi
}

createTunnel() {

  run_ssh_command -o ExitOnForwardFailure=yes \
	-R $MOBMAC_SSHD_PORT_ON_PROXY:localhost:$MOBMAC_SSHD_PORT

    if [[ $? -eq 0 ]]; then
        echolog "Tunnel to $PROXY_HOST created successfully"
    else
        echolog "An error occurred creating a tunnel to $PROXY_HOST RC was $?"
    fi
}

close_tunnel() {
	ssh $PROXY_USERNAME@$PROXY_HOST $SSH_COMMON -S $MONITOR_SOCKET_ON_MOBMAC -O exit
}

function echolog {
  local MESSAGE="$(date +'%F %H:%M:%S') - $*"
  echo $MESSAGE
  ccalog $MESSAGE
}





function generate_ssh_id {
	# usage:
	#   generate_ssh_id /path/to/ssh_id_file
	local SSH_ID_FILE=$1
	local SSH_ID_DIR=$(dirname "$SSH_ID_FILE")

	#debug
	#echo "SSH ID FILE: $SSH_ID_FILE"
	#echo "DIRNAME: $SSH_ID_DIR"
	#exit

	if [ ! -f "$SSH_ID_FILE" ]; then
		echolog "Generating SSH ID Key..."
		mkdir -p "$SSH_ID_DIR"
		ssh-keygen -N "" -f "$SSH_ID_FILE"
	else
		echolog "SSH ID Key exists, continue..."
	fi
}


is_link_working() {
  #ssh $PROXY_USERNAME@$PROXY_HOST -p $PROXY_SSHD_PORT \
  #	-o PubkeyAuthentication=no -o PasswordAuthentication=no \
  #	$SSH_COMMON -S $MONITOR_SOCKET_ON_MOBMAC exit 0 &> /dev/null
  local MOBMAC_KEY=$(run_ssh_command ssh-keyscan -p $MOBMAC_SSHD_PORT_ON_PROXY localhost 2> /dev/null)
  if [[ "x$MOBMAC_KEY" == "x" ]]; then
    return 1
  else
    return 0
  fi
}

get_ssh_id_fingerprint() {

  ccalog "get_ssh_id_fingerprint"
  local FINGERPRINT="$(ssh-keygen -E md5 -lf "$SSH_ID_FILE" 2> /dev/null | awk '{print $2}' | sed 's/^MD5:\(.*\)$/\1/')"

  if [[ "$FINGERPRINT" == "" ]]; then
    FINGERPRINT="$(ssh-keygen -lf "$SSH_ID_FILE" | awk '{print $2}')"
  fi
  echo $FINGERPRINT
}


get_mobmac_sshd_port_on_proxy() {

  ccalog "entering get_mobmac_sshd_port_on_proxy"
  local MOBMAC_ID="$1"
  local REMOTE_COMMAND="pns-getport $MOBMAC_ID"
  local MOBMAC_SSHD_PORT_ON_PROXY=$(run_ssh_command $REMOTE_COMMAND)
  echo $MOBMAC_SSHD_PORT_ON_PROXY
  ccalog "exiting get_mobmac_sshd_port_on_proxy"

}

get_mobmac_sshd_port() {
  ccalog "get_mobmac_sshd_port"
  local MOBMAC_PORT=$(grep Port /etc/ssh/sshd_config | awk '{print $2}')
  echo $MOBMAC_PORT
}


print_settings() {
  echolog "MOBMAC_ID: $MOBMAC_ID"
  echolog "Bind localhost:$MOBMAC_SSHD_PORT -> server:$MOBMAC_SSHD_PORT_ON_PROXY"
}



# ------------------------- /LIBRARY FUNCTIONS ----------------------------------- #




# static settings
SSH_ID_FILE="$SCRIPT_DIR/ssh_keys/test_id"
LOG_FILE="${SCRIPT_PATH}.log"
LOG_FILE_SIZE_LIMIT="100000" # in Bytes

# get configuration files
DEFAULT_CONF_FILE="$SCRIPT_DIR/default-conf.sh"
MOBMAC_CONF_FILE="$SCRIPT_DIR/mobmac-conf.sh"

# use default configuration file, overwrite user changes
# if there is no user configuration file, create it.
. "$DEFAULT_CONF_FILE"
. "$MOBMAC_CONF_FILE" &> /dev/null
if [[ $? -ne 0 ]]; then
  echo "No user configuration file found, creating one."
  echo "Please edit your configuration file"
  cp "$DEFAULT_CONF_FILE" "$MOBMAC_CONF_FILE"
  exit
fi

# get proxy settings
echolog "Getting proxy settings"
proxy_settings

# no need to change
MONITOR_SOCKET_ON_MOBMAC="/tmp/ssh_master-%r@%h:%p.sock"
MOBMAC_SSH_SOCKET_TO_USE="/tmp/ssh_master-$PROXY_USERNAME@$PROXY_HOST:$PROXY_SSHD_PORT.sock"

if [[ $1 == "help" ]]; then
  print_usage
  exit 0
fi


croncmd=$SCRIPT_PATH
cronjob="*/2 * * * * timeout 60s bash \"$croncmd\""

if [[ $1 == "install" ]]; then
  echolog "This script will be registered to cron jobs"
  ( crontab -l | grep -v "$croncmd" ; echo "$cronjob" ) | crontab -
fi

if [[ $1 == "remove" ]]; then
  echolog "This script will be removed from cron jobs"
  ( crontab -l | grep -v "$croncmd" ) | crontab -
  exit
fi

if [[ $1 == "stop" ]]; then
  echolog "Stopping tunnel..."
  close_tunnel
  exit
fi

# generate an ID file if necessary
generate_ssh_id "$SSH_ID_FILE"



# check connectivity to the server
#echo -n "Checking connectivity to the server: "
echolog "Checking server connectivity"
ping -c 1 $PROXY_HOST &> /dev/null

echolog "Connection Checking Disabled!"
CONNECTION_ERROR=0

if [[ $CONNECTION_ERROR -ne 0 ]]; then
  #echo "NO CONNECTION"
  echolog "No connection to the server. Quitting."
else
  echolog "Connectivity to the server is OK."

  # register ID file if necessary
  register_ssh_id "$PROXY_USERNAME@$PROXY_HOST" $PROXY_SSHD_PORT "$SSH_ID_FILE"

  echolog "Creating ssh socket"
  create_ssh_socket

  # make mobmac settings
  echolog "Getting MOBMAC settings"
  mobmac_settings

  # print settings
  print_settings

  if [[ "x$MOBMAC_SSHD_PORT_ON_PROXY" == "x" ]]; then
    echolog "Unknown MOBMAC_SSHD_PORT_ON_PROXY. (set manually or register on proxy server)"
    exit 2
  fi



  echolog "Checking if link is working"
  is_link_working
  if [[ $? == 0 ]]; then
    echolog "Tunnel seems working..."
  else
    echolog "Connection is broken, creating a new tunnel."

    # create tunnel
    createTunnel
  fi

fi

limit_log_file
echolog "Log file is truncated to $LOG_FILE_SIZE_LIMIT"