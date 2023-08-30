#!/usr/bin/env bash
#
# Report CPU, RAM Description Storage statistics

show_help() {
    cat << EOF
Report CPU, RAM Description Storage statistics

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

get_cpu() {
    require 'sensors' && sensors --no-adapter | awk '
        /^Core/ {
            temperature += $3
            c++
        }
        END {
            printf "󰔏 %.2f°C\n", t / c
        }
    '
    awk '/MHz/ {
        printf "󱑻 %.2f GHz\n", $NF / 1000
        exit
    }' '/proc/cpuinfo'
}

get_ram() {
    free | awk '
        $1 == "Mem:" {
            icon = ""
        }

        $1 == "Swap:" {
            icon = "󰯍"
        }

        /^(Mem|Swap):/ {
            printf "%s %.2f%%\n", icon, ($3 / $2) * 100
        }
    '
}

get_storage() {
    printf '%b\n' '\ue64d'  # 
    df --local --output='source,pcent,target' |  awk '
        /^\/?d[er]v/ {
            print gensub(/^.*?([0-9]+%)\s*(.*)/, "\\2: \\1", 1, $0)
        }
    '
}

get_stats() {
    get_cpu
    get_ram
    get_storage
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    get_stats | paste --serial --delimiter=" "
}

main "${@}"
