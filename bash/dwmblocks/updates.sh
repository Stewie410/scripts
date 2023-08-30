#!/usr/bin/env bash
#
# Get count of available package updates
#
# Requires:
#   - Aura (Pacman)

show_help() {
    cat << EOF
Get count of available package updates

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

is_running() {
    pidof 'pacman' 'aura' &>/dev/null
}

is_offline() {
    ping -c 1 '8.8.8.8' |& \
        grep --quiet --ignore-case 'unreachable'
}

ucount() {
    awk '!seen[$1]++' | wc --lines
}

aur() {
    aura --aursync --delmakedeps --dryrun | ucount
}

official() {
    aura --query --quiet --upgrades | ucount
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    require 'aura' || return 1
    is_running && return 1
    is_offline && return 1

    printf '󰚰 %d | %d' "$(aur)" "$(official)"
}

main "${@}"
