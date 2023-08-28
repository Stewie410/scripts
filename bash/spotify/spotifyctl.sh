#!/usr/bin/env bash
#
# Spotify DBUS wrapper
# Based on: https://gist.github.com/wandernauta/6800547
#
# Requires:
#   - spotify
#   - dbus-send

show_help() {
    cat << EOF
Spotify DBUS wrapper

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -t, --toggle        Toggle playback
    -n, --next          Go to next track
    -p, --prev          Go to previous track
    -c, --current       Format the currently playing track
    -m, --meta          Dump the current track's metadata
    -a, --art           Print the URL to the current track's album art
    -u, --url           Print the URL to the current track
    -o, --open URI      Open a URI (spotify:...) in spotify
    -q, --query QUERY   Perform a search for QUERY
EOF
}

init_defaults() {
    dbus['dest']='org.mpris.MediaPlayer2.spotify'
    dbus['path']='/org/mpris/MediaPlayer2'
    dbus['memb']='org.mpris.MediaPlayer2.Player'
}

dump_metadata() {
    dbus-send \
        --print-reply \
        --dest="${dbus['dest']}" \
        "${dbus['path']}" \
        'org.freedesktop.DBus.Properties.Get' \
        "string:${dbus['memb']}" \
        'string:Metadata'
}

spotify_send() {
    local member
    member="${dbus['memb']}.${1}"
    shift

    dbus-send \
        --print-reply \
        --dest="${dbus['dest']}" \
        "${dbus['path']}" \
        "${member}" \
        "${@}" >/dev/null
}

spotify_open() {
    spotify_send 'OpenUri' "string:${1}"
}

main() {
    local -A settings dbus
    local opts
    opts="$(getopt \
        --options htnpcmauoq: \
        --longoptions help,toggle,next,prev,current,meta,art,url,open:,query: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -t | --toggle )     settings['toggle']="1";;
            -n | --next )       settings['goto']="1";;
            -p | --prev )       settings['goto']"-1";;
            -c | --current )    settings['current']="1";;
            -m | --meta )       settings['meta']="1";;
            -a | --art )        settings['art']="1";;
            -u | --url )        settings['url']="1";;
            -o | --open )       settings['open']="${2}"; shift;;
            -q | --query )      settings['query']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

}

exit 1

main "${@}"
