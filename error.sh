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
