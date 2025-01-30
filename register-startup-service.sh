#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory
# $_sdir : this script's real file's directory

show_help(){
    cat <<HELP

    $(basename $0) --name my-service-name --start-exe /path/to/my-exe

    Options:

        --name      : Service name
        --start-exe       : Path to the exe to start
        --stop-exe	: Separate exe to stop the services
	--user 		: User to run the script

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
name=
start_exe=
stop_exe=
user=
# ---------------------------
args_backup=("$@")
args=()
_count=1
while [ $# -gt 0 ]; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --name) shift
            name="$1"
            ;;
        --start-exe) shift
            start_exe="$1"
            ;;
        --stop-exe) shift
            stop_exe="$1"
            ;;
        --user) shift
            user="$1"
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            help_die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]-}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  


# Empty argument checking
# -----------------------------------------------
[[ -z ${name:-} ]] && die "Name can not be empty"
[[ -z ${start_exe:-} ]] && die "start-exe should be provided"
start_exe="$(realpath $start_exe)"

service_file="/etc/systemd/system/$name.service"

[[ -f $service_file ]] && die "Service file exists in $service_file, delete it first."

# All checks are done, run as root starting from this point.
[[ $(whoami) = "root" ]] || exec sudo "$0" "$@"

if [[ -z ${stop_exe:-} ]]; then
    echo "No stop-exe is provided, we are passing --stop parameter to the same exe"
    stop_exe="$start_exe --stop"
fi

if [[ -z ${user:-} ]]; then
    user=${SUDO_USER:-root}
    echo  "Using default user: $user"
fi


echo
echo "---------------------- Service File --------------------------"
cat << EOF | tee $service_file
[Unit]
Description=Startup service
After=network.target
After=systemd-user-sessions.service
After=network-online.target
After=systemd-networkd-wait-online.service
Wants=systemd-networkd-wait-online.service
 
[Service]
User=$user
Type=oneshot
RemainAfterExit=yes
ExecStart=$start_exe
ExecStop=$stop_exe
 
[Install]
WantedBy=multi-user.target

EOF
echo "------------------------------------------------------------"
echo "Saved as $service_file"

chmod 644 $service_file

echo "Enabling $name.service to run on boot"
sudo systemctl enable $name

cat << EOL

If you want to start $name.service now:

	sudo systemctl start $name

To debug the service:

    sudo journalctl -xe -u $name.service

EOL
