#!/usr/bin/env bash
#
# Generate psuedo-random strings

show_help() {
    cat << EOF
Generate psuedo-random strings

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -a, --alpha             Include lower-case letters [a-z]
    -A, --ALPHA             Include upper-case letters [A-Z]
    -1, --digit             Include digits [0-9]
    -g, --log               Include basic logograms [!@#\$%&]
    -G, --extra-log         Include extra logograms [^\`~]
    -p, --punctuation       Include common punctuation [,.:;]
    -d, --dash              Include dash-like characters [_-]
    -s, --slash             Include slash-like characters [\\|/]
    -S, --space             Include whitepsace [ ]
    -m, --math              Include arithmetic operators [<>*-+!?=]
    -b, --brace             Include brace-like characters [\\[\\](){}]
    -q, --quote             Include quotes ['"]
    -D, --default           Equivalent to -aA1g
    -e, --everything        Equivalent to -DGpdsSmbq
    -i, --include CHARS     Include CHARS in character list
    -l, --length INT        String length (default: ${defaults['length']})
    -c, --count INT         Number of strings to generate (default: ${defaults['count']})
EOF
}

init_defaults() {
    local i

    defaults['length']="12"
    defaults['count']="1"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

is_valid_int() {
    if [[ "${2}" =~ [^0-9\-] ]]; then
        printf '%s is not an integer: %s\n' "${1}" "${2}" >&2
        return 1
    fi

    if (( ${2} < 1 )); then
        printf '%s must be at least 1: %s\n' "${1}" "${2}" >&2
        return 1
    fi

    return 0
}

get_string() {
    tr -dc "${settings['filter']}" < "/dev/urandom" | \
        head --bytes="${settings['length']}"
    printf '\n'
}

get_list() {
    local i

    for ((i = 0; i < settings['count']; i++)); do
        get_string
    done
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options haA1gGpdsSmbqDei:l:c: \
        --longoptions help,alpha,ALPHA,digit,log,extra-log,punctuation,dash \
        --longoptions slash,space,math,brace,quote,default,everything \
        --longoptions include:,length:,count: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )           show_help; return 0;;
            -a | --alpha )          settings['filter']+='a-z';;
            -A | --ALPHA )          settings['filter']+='A-Z';;
            -1 | --digit )          settings['filter']+='0-9';;
            -g | --log )            settings['filter']+='!@#$%&';;
            -G | --extra-log )      settings['filter']+='^`~';;
            -p | --punctuation )    settings['filter']+=',.:;';;
            -d | --dash )           settings['filter']+='_\-';;
            -s | --slash )          settings['filter']+='\\/|';;
            -S | --space )          settings['filter']+=' ';;
            -m | --math )           settings['filter']+='<>*+!?=';;
            -b | --brace )          settings['filter']+='[]{}()';;
            -q | --quote )          settings['filter']+="'\"";;
            -i | --include )        settings['filter']+="${2}"; shift;;
            -D | --default )        settings['filter']+='a-zA-Z0-9!@#$%&';;
            -e | --everything )
                settings['filter']+='a-zA-Z0-9!@#$%&^`~,.:;_\\/| <>*+!?=[]{}()'
                settings['filter']+="'\"\-"
                ;;
            -l | --length )         settings['length']="${2}"; shift;;
            -c | --count )          settings['count']="${2}"; shift;;
            -- )                    shift; break;;
            * )                     break;;
        esac
        shift
    done

    if [[ -z "${settings['filter']}" ]]; then
        printf 'No character sets selected\n' >&2
        return 1
    fi

    is_valid_int "Count" "${settings['count']}" || return 1
    is_valid_int "Length" "${settings['length']}" || return 1

    get_list
}

main "${@}"
