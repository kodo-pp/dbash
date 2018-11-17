declare -ag _db_io_data=()

function read_db() {
    local db_file="${1}"
    readarray -t _db_io_data < "${db_file}"
}

function write_db() {
    local db_file="${1}"
    printf "%s\n" "${_db_io_data[@]}" > "${db_file}"
}

function db_section_append() {
    local section_name="${1}"
    local to_append="${2}"
    local section_span=($(db_find_section "${section_name}"))
    local section_begin_index="${section_span[0]}"
    local section_end_index="${section_span[1]}"
    stderr "db_section_append: begin_index = ${section_begin_index}"
    stderr "db_section_append: end_index = ${section_end_index}"
    local insert_index="${section_end_index}"
    stderr "db_section_append: insert_index = ${insert_index}"
    _db_io_data=("${_db_io_data[@]:0:${insert_index}}" "${to_append}" "${_db_io_data[@]:${insert_index}}")
}

function db_find_section() {
    local i
    for (( i = 0; i < "${#_db_io_data[@]}"; ++i )); do
        stderr "db[$i] = '${_db_io_data[$i]}'"
    done
    local section_name="${1}"
    local length="${#_db_io_data[@]}"
    local section_begin_index=0
    while true; do
        if [[ "${section_begin_index}" -ge "${length}" ]]; then
            panic "Unable to find section '${section_name}'. Database left untouched"
        fi
        local line="${_db_io_data[${section_begin_index}]}"
        if [[ "${line}" == ".${section_name}" ]]; then
            break
        fi
        (( ++section_begin_index ))
    done
    local section_end_index="$(( ${section_begin_index} + 1 ))"
    while true; do
        if [[ "${section_end_index}" -ge "${length}" ]]; then
            break
        fi
        local line="${_db_io_data[${section_end_index}]}"
        if [[ "${line:0:1}" == "." ]]; then
            break
        fi
        (( ++section_end_index ))
    done
    echo "${section_begin_index} ${section_end_index}"
    stderr "db_find_section(...) = ${section_begin_index} ${section_end_index}"
}

function db_find_regex_between() {
    local regex="${1}"
    local begin_index="${2}"
    local end_index="${3}"
    local index="${begin_index}"
    while [[ "${index}" -lt "${end_index}" ]]; do
        if [[ ${_db_io_data[${index}]} =~ ${regex} ]]; then
            echo "${index}"
            stderr "db_find_regex_between(...) = ${index}"
            return 0
        fi
        (( ++index ))
    done
    panic "Regex not found: '${regex}'. Database left untouched"
}

function db_section_read_between_regex() {
    local section_name="${1}"
    local begin_regex="${2}"
    local end_regex="${3}"
    local include_begin="${4}"
    local include_end="${5}"
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_begin}" == "include" -o "${include_begin}" == "exclude" ]
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_end}" == "include" -o "${include_end}" == "exclude" ]
    local section_bounds="$(db_find_section "${section_name}")"
    local section_begin_index="$(echo "${section_bounds}" | awk '{print $1}')"
    local section_end_index="$(echo "${section_bounds}" | awk '{print $2}')"
    local regex_begin_index="$(db_find_regex_between "${begin_regex}" "${section_begin_index}" "${section_end_index}")"
    local regex_end_index="$(db_find_regex_between "${end_regex}" "${regex_begin_index}" "${section_end_index}")"
    
    local index="${regex_begin_index}"
    while [[ "${index}" -le "${regex_end_index}" ]]; do
        if [[ "${index}" == "${regex_begin_index}" && "${include_begin}" == "exclude" ]]; then
            continue
        fi
        if [[ "${index}" == "${regex_end_index}" && "${include_end}" == "exclude" ]]; then
            continue
        fi
        echo "${_db_io_data[${index}]}"
    done
}

function db_section_delete_between_regex() {
    local section_name="${1}"
    local begin_regex="${2}"
    local end_regex="${3}"
    local include_begin="${4}"
    local include_end="${5}"
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_begin}" == "include" -o "${include_begin}" == "exclude" ]
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_end}" == "include" -o "${include_end}" == "exclude" ]
    local section_bounds="$(db_find_section "${section_name}")"
    local section_begin_index="$(echo "${section_bounds}" | awk '{print $1}')"
    local section_end_index="$(echo "${section_bounds}" | awk '{print $2}')"
    local regex_begin_index="$(db_find_regex_between "${begin_regex}" "${section_begin_index}" "${section_end_index}")"
    local regex_end_index="$(db_find_regex_between "${end_regex}" "${regex_begin_index}" "${section_end_index}")"
    
    if [[ "${include_begin}" == "exclude" ]]; then
        (( ++regex_begin_index )) || true
    fi
    if [[ "${include_end}" == "include" ]]; then
        (( ++regex_end_index )) || true
    fi
    _db_io_data=("${_db_io_data[@]:0:${regex_begin_index}}" "${_db_io_data[@]:${regex_end_index}}")
}

function db_section_insert_before_regex() {
    local section_name="${1}"
    local begin_regex="${2}"
    local end_regex="${3}"
    local include_begin="${4}"
    local include_end="${5}"
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_begin}" == "include" -o "${include_begin}" == "exclude" ]
    assert \
        "Invalid include/exclude argument passed to db_section_read_between_regex" \
        [ "${include_end}" == "include" -o "${include_end}" == "exclude" ]
    local section_bounds="$(db_find_section "${section_name}")"
    local section_begin_index="$(echo "${section_bounds}" | awk '{print $1}')"
    local section_end_index="$(echo "${section_bounds}" | awk '{print $2}')"
    local regex_begin_index="$(db_find_regex_between "${begin_regex}" "${section_begin_index}" "${section_end_index}")"
    local regex_end_index="$(db_find_regex_between "${end_regex}" "${regex_begin_index}" "${section_end_index}")"
    
    if [[ "${include_begin}" == "exclude" ]]; then
        (( ++regex_begin_index ))
    fi
    if [[ "${include_end}" == "include" ]]; then
        (( --regex_end_index ))
    fi
    _db_io_data=("${_db_io_data[@]:0:${regex_begin_index}}" "${_db_io_data[@]:${regex_end_index}}")
}

function db_section_insert_before_regex() {
    local section_name="${1}"
    local regex="${2}"
    local to_append="${3}"
    local regex_index="$(db_find_regex_between $(db_find_section "${section_name}"))"
    _db_io_data=("${_db_io_data[@]:0:${regex_index}}" "${to_append}" "${_db_io_data[@]:${regex_index}}")
}
