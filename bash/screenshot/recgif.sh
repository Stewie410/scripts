#!/usr/bin/env bash
#
# use wf-recorder, slurp & ffmpeg to create a gif

cleanup() {
    rm --recursive --force "${stage}"
    umask 022
    unset stage
}

show_help() {
    cat << EOF
use wf-recorder, slurp & ffmpeg to create a gif

USAGE: ${0##*/} [OPTIONS] TIME

OPTIONS:
    -h, --help          Show this help message
    -k, --keep-alive    Do not automatically kill wf-recorder
    -o, --outfile FILE  Save gif to FILE
                        (default: ${defaults['outfile']})
EOF
}

init_defaults() {
    defaults['outfile']="${HOME}/Videos/$(date '%F-%H-%M-%S').gif"
    settings['outfile']="${defaults['outfile']}"
}

require() {
    local err

    while (( $# > 0 )); do
        if ! command -v "${1}" &>/dev/null; then
            printf 'Missing required application: %s\n' "${1}" >&2
            (( err++ ))
        fi
        shift
    done

    return "${err:-0}"
}

require_wayland() {
    [[ -n "${WAYLAND_DISPLAY}" ]] && return 0
    printf 'Requires wayland to function\n' >&2
    return 1
}

stop_recorder() {
    pkill --euid "${USER}" --signal 'SIGINT' 'wf-recorder'
}

start_recorder() {
    timeout "${settings['timeout']}" \
        wf-recorder --geometry "${1}" "${2}"
}

gen_palette() {
    ffmpeg \
        -i "${capture}" \
        -filter_complex 'palettegen=stats_mode=full' \
        "${1}" \
        -y
}

gen_gif() {
    ffmpeg \
        -i "${1}" \
        -i "${2}" \
        -filter_complex 'paletteuse=dither=sierra2_4a' \
        "${settings['outfile']}" -y
}

record() {
    local coords capture palette

    stop_recorder
    umask 117

    coords="$(slurp)" || return 1
    capture="${stage}/cap.mp4"
    palette="${stage}/pal.png"

    printf 'Starting region capture: %s\n' "${coords}"
    if ! start_recorder "${coords}" "${capture}"; then
        stop_recorder
        return 1
    fi

    if ! gen_palette "${palette}"; then
        printf 'Failed to generate palette file\n' >&2
        return 1
    fi

    umask 022
    mkdir --parents "${settings['outfile']%/*}"

    printf 'Generating gif: %s\n' "${settings['outfile']}"
    if ! gen_gif "${capture}" "${palette}"; then
        printf 'Failed to generate gif\n' >&2
        return 1
    fi

    return 0
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hko: \
        --longoptions help,keep-alive,outfile: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -k | --keep-alive ) settings['timeout']="0";;
            -o | --outfile )    settings['outfile']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require_wayland || return 1
    require 'wf-recorder' 'slurp' 'ffmpeg' || return 1

    record
}

stage="$(mktemp --directory)"
trap cleanup EXIT
main "${@}"
