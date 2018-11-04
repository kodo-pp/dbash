function main() {
    local top_level_action="${1}"
    shift
    case "${top_level_action}" in
        "begin-transaction")
            action_begin_transaction "$@"
            ;;
        "commit-transaction")
            action_commit_transaction "$@"
            ;;
        "rollback-transaction")
            action_rollback_transaction "$@"
            ;;
        "add")
            action_add "$@"
            ;;
        "remove")
            action_remove "$@"
            ;;
        "get")
            action_get "$@"
            ;;
        "version")
            action_version "$@"
            ;;
        *)
            action_help "$@"
            ;;
    esac
}
