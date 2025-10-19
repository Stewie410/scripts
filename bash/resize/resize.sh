#!/usr/bin/env bash
#
# Based on rsz()
# https://wiki.archlinux.org/title/Working_with_the_serial_console

rsz() {
    _unsupported() {
        printf 'Unsupported terminal emulator\n' >&2
    }

    if [[ -n "${1}" || ! -t 0 ]]; then
        cat << EOF
Bash implementation of xterm's "resize", for use with console sessions

USAGE: ${FUNCNAME[0]} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
EOF
        return 0
    fi

    local IFS='[;'
    local geometry x y escaped

    printf '\e7\e[r\e[999;999H\e[6n\e8'
    if ! read -t 5 -sd R escaped geometry; then
        _unsupported
        return 1
    fi

    x="${geometry##*;}"
    y="${geometry%%;*}"

    if (( COLUMNS == x && LINES == y )); then
        printf '%s %dx%d\n' "${TERM}" "${x}" "${y}"
    elif (( x > 0 && y > 0 )); then
        printf '%dx%d -> %dx%d\n' "${COLUMNS}" "${LINES}" "${x}" "${y}"
        stty cols "${x}" rows "${y}"
    else
        _unsupported
        return 1
    fi

    return 0
}
