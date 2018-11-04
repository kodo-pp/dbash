declare -ag _db_io_data=()

function read_db() {
    local db_file="${1}"
    readarray _db_io_data < "${db_file}"
}

function write_db() {
    local db_file="${1}"
    printf "%s\n" "${_db_io_data[@]}" > "${db_file}"
}

function db_section_append() {
    local section_name="${1}"
    local to_append="${2}"
    local section_begin_index=0
    for line in "${_db_io_data[@]}"; do
        if [[ "${line}" == ".${section_name}" ]]; then
            break
        fi
        (( ++section_begin_index ))
    done
    local section_end_index="$(( ${section_begin_index} + 1 ))"
    local length="${#_db_io_data[@]}"
    while "${section_end_index}"; do
        if [[ "${line}" == "." ]]; then
            break
        fi
        (( ++section_begin_index ))
    done
}
