function action_begin_transaction() {
    parse_arguments \
        -f str 'database file' db_file             required \
        -c str 'comment'       transaction_comment optional \
        -- "$@"
    local db_file="$(get_argument 'db_file')"
    local comment="$(get_argument 'transaction_comment' '')"
    begin_transaction "${db_file}" "${comment}"
}

function action_commit_transaction() {
    parse_arguments \
        -f str  'database file'  db_file        required \
        -T str  'transaction id' transaction_id required \
        -F flag 'force commit'   force          x \
        -- "$@"
    local db_file="$(get_argument 'db_file')"
    local transaction_id="$(get_argument 'transaction_id')"
    local force="$(get_flag 'force' 'force=yes' 'force=no')"
    commit_transaction "${db_file}" "${transaction_id}" "${force}"
}

function action_rollback_transaction() {
    parse_arguments \
        -f str 'database file'  db_file        required \
        -T str 'transaction id' transaction_id required \
        -- "$@"
    local db_file="$(get_argument 'db_file')"
    local transaction_id="$(get_argument 'transaction_id')"
    rollback_transaction "${db_file}" "${transaction_id}"
}

function begin_transaction() {
    local db_file="${1}"
    local comment="${2}"
    local transaction_id="$(generate_transaction_id)"
    validate_transaction_id "${transaction_id}"

    acquire_db_lock "${db_file}"
    db_section_append "transaction_data" "BEGIN ${transaction_id} $(base64_encode "${comment}")"
    db_section_append "transaction_data" "END ${transaction_id}"
    release_db_lock "${db_file}"
    echo "${transaction_id}"
}

function commit_transaction() {
    local db_file="${1}"
    local transaction_id="${2}"
    local force="${3}"
    validate_transaction_id "${transaction_id}"

    acquire_db_lock "${db_file}"
    local action
    local args_str
    db_section_read_between_regex \
        "transaction_data" \
        "BEGIN ${transaction_id} [a-zA-Z0-9/+=]*" \
        "END ${transaction_id}" \
        exclude exclude \
    | while read -r action args_str; do
        local args=(${args_str})
        case "${action}" in
            "add")
                add_item "${args[0]} ${args[1]}" "${force}"
                ;;
            "rm")
                remove_item "${args[0]}" "${force}"
                ;;
            "set")
                modify_item "${args[0]} ${args[1]}" "${force}"
                ;;
            *)
                panic "Unknown transaction action: ${action}. Database left untouched"
                ;;
        esac
    done
    db_section_delete_between_regex \
        "transaction_data" \
        "BEGIN ${transaction_id} [a-zA-Z0-9/+=]*" \
        "END ${transaction_id}" \
        include include
    release_db_lock "${db_file}"
}

function rollback_transaction() {
    local db_file="${1}"
    local transaction_id="${2}"
    validate_transaction_id "${transaction_id}"

    acquire_db_lock "${db_file}"
    db_section_delete_between_regex \
        "transaction_data" \
        "BEGIN ${transaction_id} [a-zA-Z0-9/+=]*" \
        "END ${transaction_id}" \
        include include
    release_db_lock "${db_file}"
}

function add_to_transaction() {
    local db_file="${1}"
    local transaction_id="${2}"
    local string_to_append="${3}"

    acquire_db_lock "${db_file}"
    db_section_insert_before_regex \
        "transaction_data" \
        "END ${transaction_id}" \
        "${string_to_append}"
    release_db_lock "${db_file}"
}

function validate_transaction_id() {
    local transaction_id="${1}"
    if ! [[ ${transaction_id} =~ ^[0-9a-fA-F]{64}$ ]]; then
        panic "Invalid transaction id: ${transaction_id}"
    fi
}

function generate_transaction_id() {
    local random_bytes=500
    head -c "${random_bytes}" /dev/urandom | sha256sum - | awk '{print $1}'
}

function action_add() {
    set -x
    parse_arguments \
        -f str 'database file'  db_file        required \
        -T str 'transaction id' transaction_id required \
        -k str 'key'            key            required \
        -v str 'value'          value          required \
        -- "$@"
    local db_file="$(get_argument 'db_file')"
    local transaction_id="$(get_argument 'transaction_id')"
    local key="$(get_argument 'key')"
    local value="$(get_argument 'value')"
    validate_transaction_id "${transaction_id}"

    acquire_db_lock "${db_file}"
    db_section_insert_before_regex \
        "transaction_data" \
        "^END ${transaction_id}\$" \
        "add $(base64_encode "${key}") $(base64_encode "${value}")"
    release_db_lock "${db_file}"
}
