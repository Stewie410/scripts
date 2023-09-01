#!/usr/bin/env bash
#
# Expand a CIDR address to a list of IPv4 addresses

cleanup() {
    unset log
}

log() {
    printf '%s|%s|%s\n' "$(date --iso-8601=sec)" "${FUNCNAME[1]}" "${1}" | \
        tee --append "${log:-/dev/null}" | \
        cut --fields="2-" --delimiter="|"
}

show_help() {
    cat << EOF
Expand a CIDR address to a list of IPv4 addresses

USAGE: ${0##*/} [OPTIONS] FILE

OPTIONS:
    -h, --help      Show this help message
EOF
}

is_valid() {
    local -r octet='([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
    local -r cidr='(/([1-9]|[12][0-9]|3[0-2]))'
    [[ "${1}" =~ ^(${octet}\.){3}${octet}${cidr}? ]]
}

expand() {
    local a b c d mask current end

    IFS='.' read -r a b c d <<< "${1%/*}"
    mask="$(( (1 << (32 - ${1#*/})) - 1 ))"
    current="$(( ( (a << 24) + (b << 16) + (c << 8) + d) & ~mask ))"
    end="$(( current | mask ))"

    for (( ; current <= end; current++ )); do
        printf '%d.%d.%d.%d\n' \
            "$(( (current >> 24) & 0xFF ))" \
            "$(( (current >> 16) & 0xFF ))" \
            "$(( (current >> 8) & 0xFF ))" \
            "$(( current & 0xFF ))"
    done
}

main() {
    local cidr

    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" || "${1}" == "-" ]]; then
        set -- '/dev/stdin'
    fi

    while read -r cidr; do
        if ! is_valid "${cidr}"; then
            printf 'Invalid address format: %s\n' "${cidr}" >&2
        elif [[ "${cidr}" != */* ]]; then
            printf '%s\n' "${cidr}"
        else
            expand "${cidr}"
        fi
    done < "${1}"
}

main "${@}"
