#!/usr/bin/env bash
#
# Get apt package history

show_help() {
    cat << EOF
Get apt package history, optionally by action

USAGE: ${0##*/} [OPTIONS] [ACTION]

OPTIONS:
    -h, --help          Show this help message

ACTION:
If specified, list packages by action (case-insensitive):

    /i(nstall(ed)?)?/       Installed Packages
    /u(p(date|grade)d?)?/   Upgraded Packages
    /r(emoved?)?/           Removed Packages

If none specified, print logs to stdout
EOF
}

get_log() {
    find '/var/log/apt' -type f -iname 'history.log.*.gz' -exec zcat {} +
    cat '/var/log/apt/history.log'
}

filter() {
    sed --quiet "s/^${1}: //p" | sed 's/),\s\+/)\n/g'
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    case "${1,,}" in
        i | install | installed )
            get_log | filter "Install"
            ;;
        u | upgrade | upgraded | update | updated )
            get_log | filter "Upgrade"
            ;;
        r | remove | removed )
            get_log | filter "Remove"
            ;;
        '' )
            get_log
            ;;
        * )
            printf 'Unknown action: %s\n' "${1}" >&2
            return 1
            ;;
    esac

    return 0
}

main "${@}"
