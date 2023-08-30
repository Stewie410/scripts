#!/usr/bin/env bash
#
# Re-/Start Polybar

show_help() {
    cat << EOF
Re-/Start Polybar

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
EOF
}

kill_pb() {
    killall --quiet polybar
    while pidof polybar &>/dev/null; do
        sleep 1
    done
}

launch() {
    polybar \
        --config="${XDG_CONFIG_HOME}/.config/polybar/config.ini" \
        topbar & disown
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    kill_pb
    launch
}

main "${@}"
