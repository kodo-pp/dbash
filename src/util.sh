function assert() {
    local message="${1}"
    shift
    if ! "$@"; then
        stderr "Assertion failed"
        stderr "Message: ${message}"
        panic "Internal error: assertion failed"
    fi
}

function panic() {
    local message="${1}"
    stderr -e "\e[31mError: ${message}\e[0m"
    release_all_locks
    kill -TERM "${MAIN_BASH_PROCESS}"
    kill -KILL "${MAIN_BASH_PROCESS}"
    exit 77
}

function logical_not() {
    if "$@"; then
        return 1
    else
        return 0
    fi
}

function stderr() {
    echo "$@" >&2
}
