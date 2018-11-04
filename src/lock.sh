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
}

function release_lock() {
    local file="${1}"
    local lockfile="${file}.lock"
    rm "$(lockfile)"
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
