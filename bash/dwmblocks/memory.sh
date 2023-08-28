#!/usr/bin/env bash
#
# Display memory utilization

show_help() {
    cat << EOF
Display memory utilization

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
EOF
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        usage
        return 0
    fi

    free --human --si | awk '
        /^Mem/ {
            printf " %s / %s", $3, $2
        }
    '
}

main "${@}"
