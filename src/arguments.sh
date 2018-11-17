declare -Ag _arguments_argdefs
declare -Ag _arguments_argmap

function parse_arguments() {
    local args=("$@")
    local offset=0
    local count="${#args[@]}"

    declare -A flags
    declare -A str_args

    while true; do
        assert \
            "invalid parameters passed to parse_arguments(): offset >= count" \
            [ "${offset}" -lt "${count}" ]
        local arg_flag="${args[$offset]}"
        assert \
            "invalid parameters passed to parse_arguments(): arg_flag[0] != '-' (offset = ${offset})" \
            [ "${arg_flag:0:1}" == "-" ]
        if [[ "${arg_flag}" == "--" ]]; then
            (( ++offset ))
            break
        fi

        assert \
            "invalid parameters passed to parse_arguments(): offset + 4 >= count" \
            [ $(( "${offset}" + 1 )) -lt "${count}" ]
        local arg_type="${args[$(( $offset + 1 ))]}"
        local arg_description="${args[$(( $offset + 2 ))]}"
        local arg_name="${args[$(( $offset + 3 ))]}"
        local arg_required="${args[$(( $offset + 4 ))]}"
        assert \
            "invalid parameters passed to parse_arguments(): empty argument name" \
            [ -n "${arg_name}" ]
        case "${arg_type}" in
            "flag")
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate argument: ${arg_flag}" \
                    logical_not [ "${flags[$arg_flag]+isset}" ]
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate argument: ${arg_flag}" \
                    logical_not [ "${str_args[$arg_flag]+isset}" ]
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate name: ${arg_name}" \
                    logical_not [ "${_arguments_argmap[$arg_name]+isset}" ]
                flags["${arg_flag}"]="${arg_name} ${arg_description}"
                _arguments_argdefs["${arg_name}"]="flag"
                ;;
            "str")
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate argument: ${arg_flag}" \
                    logical_not [ "${flags[$arg_flag]+isset}" ]
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate argument: ${arg_flag}" \
                    logical_not [ "${str_args[$arg_flag]+isset}" ]
                assert \
                    "invalid parameters passed to parse_arguments(): invalid required value: ${arg_required}" \
                    [ "${arg_required}" == "required" -o "${arg_required}" == "optional" ]
                assert \
                    "invalid parameters passed to parse_arguments(): duplicate name: ${arg_name}" \
                    logical_not [ "${_arguments_argmap[$arg_name]+isset}" ]
                str_args["${arg_flag}"]="${arg_required} ${arg_name} ${arg_description}"
                _arguments_argdefs["${arg_name}"]="str ${arg_required}"
                ;;
            *)
                assert \
                    "invalid parameters passed to parse_arguments(): invalid parameter type: ${arg_type}" \
                    false
        esac
        (( offset += 5 ))
    done
    while [[ "${offset}" -lt "${count}" ]]; do
        case "${args[$offset]}" in
            --help)
                stderr "Usage: ${HELP_COMMAND} [arguments]"
                stderr "Arguments:"
                stderr "  Common commands:"
                stderr "    --help - Show this help and exit"
                stderr "    --version - Show version information and exit"
                if [[ "${#flags[@]}" -gt 0 ]]; then
                    stderr "  Flags:"
                    local i
                    for i in "${!flags[@]}"; do
                        local argdata="${flags[$i]}"
                        local name
                        local desc
                        echo "${argdata}" | (
                            read -r name desc
                            stderr "    ${i} - ${desc}"
                        )
                    done
                fi
                if [[ "${#str_args[@]}" -gt 0 ]]; then
                    stderr "  Arguments:"
                    local i
                    for i in "${!str_args[@]}"; do
                        local argdata="${str_args[$i]}"
                        local required
                        local name
                        local desc
                        echo "${argdata}" | (
                            read -r required name desc
                            stderr "    ${i} <${name}> - (${required}) ${desc}"
                        )
                    done
                fi
                exit 0
                ;;
            --version)
                echo "${VERSION_STRING}"
                exit 0
                ;;
            -*)
                local arg="${args[$offset]}"
                if [[ "${flags[$arg]+isset}" ]]; then
                    local argdata="${flags[$arg]}"
                    local name="$(echo "${argdata}" | awk '{print $1}')"
                    _arguments_argmap["${name}"]="1"
                elif [[ "${str_args[$arg]+isset}" ]]; then
                    if [[ $(( "${offset}" + 1 )) -ge "${count}" ]]; then
                        stderr "Usage error: expected an argument for '${arg}' option. See ${HELP_COMMAND} --help"
                        exit 1
                    fi
                    local argdata="${str_args[$arg]}"
                    local name="$(echo "${argdata}" | awk '{print $2}')"
                    local argarg="${args[$(( "$offset" + 1 ))]}"
                    (( ++offset ))
                    _arguments_argmap["${name}"]="${argarg}"
                fi
                ;;
            *)
                stderr "Usage error: invalid argument: '${args[$offset]}'. See ${HELP_COMMAND} --help"
                exit 1
                ;;
        esac
        (( ++offset ))
    done

    local i
    for i in "${!str_args[@]}"; do
        local argdata="${str_args[$i]}"
        local required="$(echo "${argdata}" | awk '{print $1}')"
        local name="$(echo "${argdata}" | awk '{print $2}')"
        if [[ "${required}" == "optional" ]]; then
            continue
        fi
        if ! [[ ${_arguments_argmap["${name}"]+isset} ]]; then
            stderr "Usage error: required option '${i} <${name}>' not specified. See ${HELP_COMMAND} --help"
            exit 1
        fi
    done
}

function get_arguments() {
    local i
    for i in "${!_arguments_argmap[@]}"; do
        echo "${i} = ${_arguments_argmap[$i]}"
    done
}

function get_argument() {
    local name="${1}"
    assert \
        "Argument error: no such argument: ${name}" \
        [ "${_arguments_argdefs[${name}]+isset}" ]
    local argdata="${_arguments_argdefs[${name}]}"
    local argtype="$(echo "${argdata}" | awk '{print $1}')"
    if [[ "${argtype}" == "flag" ]]; then
        local set_value="${2}"
        local unset_value="${3}"
        if [[ "${_arguments_argmap["${name}"]}" == "1" ]]; then
            echo "${set_value}"
        else
            echo "${unset_value}"
        fi
    else
        local required="$(echo "${argdata}" | awk '{print $2}')"
        if [[ "${required}" == "required" ]]; then
            echo "${_arguments_argmap["${name}"]}"
        else
            local default_value="${2}"
            if [[ "${_arguments_argmap["${name}"]+isset}" ]]; then
                echo "${_arguments_argmap["${name}"]}"
            else
                echo "${default_value}"
            fi
        fi
    fi
}

function action_help() {
    echo "Usage dbash <subcommand> [arguments]"
    echo "Available subcommands:"
    echo "  begin-transaction     Start a transaction"
    echo "  commit-transaction    Commit a transaction"
    echo "  rollback-transaction  Cancel a transaction"
    echo "  add                   Add a key-value pair"
    echo "  remove                Remove a key-value pair"
    echo "  version               Show version information and exit"
    echo "For help for a specific subcommand see 'dbash <subcommand> --help'"
    exit 1
}
