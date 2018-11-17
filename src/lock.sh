declare -Ag _lock_held_locks

function acquire_lock() {
    local file="${1}"
    local lockfile="${file}.lock"
    while true; do
        while [[ -e "${lockfile}" ]]; do
            sleep 0.2
        done
        echo "$$" > "${lockfile}"
        sleep 0.01
        if [[ "$(cat "${lockfile}")" == "$$" ]]; then
            break
        fi
    done
    _lock_held_locks["${file}"]=1
}

function release_lock() {
    local file="${1}"
    local lockfile="${file}.lock"
    _lock_held_locks["${file}"]=0
    rm "${lockfile}"
}

function acquire_db_lock() {
    local db_file="${1}"
    acquire_lock "${db_file}"
    read_db "${db_file}"
}

function release_db_lock() {
    local db_file="${1}"
    write_db "${db_file}"
    release_lock "${db_file}"
}

function release_all_locks() {
    stderr "Releasing all held locks"
    local file
    for file in "${!_lock_held_locks[@]}"; do
        if [[ "${_lock_held_locks[${file}]}" != 1 ]]; then
            continue
        fi
        local lockfile="${file}.lock"
        stderr "  Releasing lock for '${file}'"
        rm -f "${lockfile}"
    done
    stderr "All held locks released"
}
