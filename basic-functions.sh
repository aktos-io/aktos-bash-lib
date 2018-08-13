errcho () {
    >&2 echo -e "$*"
}

echo_err () {
	errcho "ERROR:"
	errcho "ERROR:"
	errcho "ERROR: $* "
	errcho "ERROR:"
	errcho "ERROR:"
	exit 1
}

die() {
    echo_err $*
}


echo_info () {
	echo_blue "INFO: $* "
}

echo_debug () {
    if $DEBUG; then
        errcho "DEBUG: $*"
    fi
}

debug_eval () {
    if $DEBUG; then
        echo_debug "$*"
    fi
    eval "$*"
}


echo_cont ()  {
    echo -ne "$*"
}

# http://webhome.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html

echo_green () {
    errcho "\e[1;32m$*\e[0m"
}

echo_blue () {
    errcho "\e[1;34m$*\e[0m"
}

echo_yellow () {
    errcho "\e[1;33m$*\e[0m"
}

echo_red () {
    errcho "\e[1;31m$*\e[0m"
}

echo_stamp () {
  local MESSAGE="$(date +'%F %H:%M:%S') - $@"
  echo $MESSAGE
}

prompt_yes_no () {
    local message=$1
    local OK_TO_CONTINUE="no"
    errcho "----------------------  YES / NO  ----------------------"
    while :; do
        >&2 echo -en "$message (yes/no) "
        read OK_TO_CONTINUE </dev/tty

        if [[ "${OK_TO_CONTINUE}" == "no" ]]; then
            return 1
        elif [[ "${OK_TO_CONTINUE}" == "yes" ]]; then
            return 0
        fi
        errcho "Please type 'yes' or 'no' (you said: $OK_TO_CONTINUE)"
        sleep 1
    done
}

get_timestamp () {
	date +%Y%m%dT%H%M
}

start_timer () {
    #echo_blue "(timer started)"
    start_date=$(date +%s)
}

show_timer () {
    local message="$*"
    if [[ -z $message ]]; then
        message="Duration: "
    fi
    end_date=$(date +%s)
    local time_diff=$(date -u -d "0 $end_date seconds - $start_date seconds" +"%H:%M:%S")
    echo_blue "$message $time_diff"
}

breakpoint () {
    echo -en "Reached debug step. Press enter to continue..."
    read hello </dev/tty
}

press_enter_to_continue () {
    message=$1
    if [ "$message" == "" ]; then
        message="Press enter to continue..."
    fi
    echo -en $message
    read hello </dev/tty
}

get_line_field () {
    # returns the word after a specific $field in a line
    local field=$1
    grep -oP "(?<=$field )[^ ]+"
}

dirname_two () {
    # return the last 2 portions of dirname:
    local param=$1
    echo "$(basename $(dirname $param))/$(basename $param)"
}

assert_test () {
    local expected=$1
    local result=$2
    if [[ "$expected" != "$result" ]]; then
        echo_err "Test failed! (expected: $expected, result: $result)"
    else
        echo_green "Test passed..."
    fi
}


# taken from https://gist.github.com/aguy/2359833
# ------------------------------------------------
trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
#trap 'trapexit $? $LINENO' EXIT

function trapexit() {
  echo "$(date) $(hostname) $0: EXIT on line $2 (exit status $1)"
}

function traperror () {
    local err=$1 # error status
    local line=$2 # LINENO
    local linecallfunc=$3
    local command="$4"
    local funcstack="$5"
    echo "$(date) $(hostname) $0: ERROR '$command' failed at line $line - exited with status: $err"

    if [ "$funcstack" != "::" ]; then
      echo -n "$(date) $(hostname) $0: DEBUG Error in ${funcstack} "
      if [ "$linecallfunc" != "" ]; then
        echo "called at line $linecallfunc"
      else
        echo
      fi
    fi
    echo "'$command' failed at line $line - exited with status: $err" | mail -s "ERROR: $0 on $(hostname) at $(date)" xxx@xxx.com
}

function log() {
    local msg=$1
    now=$(date)
    i=${#FUNCNAME[@]}
    lineno=${BASH_LINENO[$i-2]}
    file=${BASH_SOURCE[$i-1]}
    echo "${now} $(hostname) $0:${lineno} ${msg}"
}

# taken from https://stackoverflow.com/a/29779745/1952991
# Usage:
#
#   git status | indent
indent() { sed 's/^/  /'; }
indent2() { sed 's/^/    /'; }
