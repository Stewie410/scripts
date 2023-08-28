#!/usr/bin/env bash
#
# Display information about the installed battery
#
# Requires:
#   - font awesome

show_help() {
    cat << EOF
Display information about the installed battery

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
EOF
}

get_batteries() {
    find '/sys/class/power_supply' \
        -mindepth 1 \
        -maxdepth 1 \
        -ipath '*BAT*/uevent' \
        -exec readlink --canonicalize {} +
}

get_states() {
    while (( $# != 0 )); do
        awk '
            BEGIN {
                FS = "="
                OFS = " | "
            }

            function capacity_icon(level) {
                if (level >= 95)
                    return ""
                if (level >= 75)
                    return ""
                if (level >= 50)
                    return ""
                if (level >= 25)
                    return ""
                return ""
            }

            function status_icon(state) {
                if (tolower(state) == "charging")
                    return ""
                return ""
            }

            function warning_icon(level) {
                if (level < 25)
                    return "!"
                return ""
            }

            /_CAPACITY=/ {
                capacity = $NF
            }

            /_STATUS=/ {
                status = get_status_icon($NF)
            }

            END {
                printf "%s", warning_icon(capacity)
                printf "%s", status
                printf "%s %d%%\n", capacity_icon(capacity), capacity
            }
        ' "${1}"
        shift
    done
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        usage
        return 0
    fi

    local -a batteries
    mapfile -t batteries < <(get_batteries)

    get_states "${batteries[@]}" | \
        paste --serial --delimiter="|" | \
        sed 's/|/ | /g' | \
        tr -d '\n'
}

main "${@}"
