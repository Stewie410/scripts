#!/usr/bin/env bash

# level, message...|<stdin
log() {
    if (( $# == 1 )); then
        mapfile -t largs
        set -- "${1}" "${largs[@]}"
        unset largs
    fi

    local rgb lvl
    case "${1,,}" in
        emerg )     rgb='\e[1;31m'; lvl="EMERGENCY";;
        alert )     rgb='\e[1;36m'; lvl="ALERT";;
        crit )      rgb='\e[1;33m'; lvl="CRITICAL";;
        err )       rgb='\e[0;31m'; lvl="ERROR";;
        warn )      rgb='\e[0;33m'; lvl="WARNING";;
        notice )    rgb='\e[0;32m'; lvl="NOTICE";;
        info )      rgb='\e[1;37m'; lvl="INFO";;
        debug )     rgb='\e[1;35m'; lvl="DEBUG";;
    esac
    shift

    [[ -n "${NO_COLOR}" ]] && unset rgb

    while (( $# > 0 )); do
        printf '%(%FT%T)T|%b%-9s\e[0m|%s\n' -1 "${rgb}" "${lvl}" "${1}"
        shift
    done | tee >(
        sed --unbuffered $'s/\e[[][^a-zA-Z]*m//g' >> "${log:-/dev/null}"
    )
}

# cmd, [args]
exec_log() {
    __el_cleanup() {
        exec >&3-
        exec >&4-
        return "${1}"
    }

    exec 3> >(log info >&1)
    exec 4> >(log err >&2)
    ( exec "${@}" ) 1>&3 2>&4
    __el_cleanup "$?"
}
