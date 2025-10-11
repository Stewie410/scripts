#!/usr/bin/env bash

show_help() {
    cat << EOF
Send email via Mailgun API.

USAGE: ${0##*/} [OPTIONS] TO [...] < BODY

OPTIONS:
    -h, --help                  Show this help message
    -u, --usr KEY               Mailgun API Key (default: \$MAILGUN_API_KEY)
    -d, --dom DOMAIN            Mailgun Domain (default: \$MAILGUN_API_DOMAIN)

    -t, --test                  Send message in test mode

    -H, --html                  Specify body content is HTML format

        --tls                   Require sending over TLS connection only
    -k, --dkim                  Enable DKIM signatures
        --dkim2 DOMAIN          Specify a secondary DKIM domain key
        --dkim2-pub ALIAS       Specify alias of secondary DKIM key

    -f, --from "[NAME] <ADDR>"  Specify sender name & address
                                (default: "\$USER <\$USER@\$MAILGUN_API_DOMAIN>")
    -s, --subject TEXT          Use TEXT as message subject
    -c, --cc LIST               Add Comma-Separated Address LIST to the CC list
    -b, --bcc ADDRESS           Add Comma-
    -A, --amp HTML              Specify AMP part of the message
    -a, --attach PATH           Add PATH to attachments (multipart/form-data)
    -i, --inline PATH           Add PATH as inline attachment

    -T, --templ NAME            Use NAME template via the Templates API
        --templ-ver VER         Explicitly render template version VER
        --templ-txt             Also render template as plaintext
        --templ-var JSON        Input template values as JSON Dictionary

    -g, --tag TAG               Add TAG to message tags

        --delay RFC-2822        Specify delivery date/time (see date(1))
        --delay-opt HH          Specify Send Time Optimzation in hours (24-72)
        --recip-tz HH:mm[aa]    Specify delivery time to recipient's timezone

        --track OPT             Toggle click & open tracking
        --track-clicks OPT      Toggle click tracking
        --track-opens OPT       Toggle opens tracking
        --track-top-pos OPT     Place tracking pixel at top of message

        --sending-ip ADDR       Set sending IP ADDR
        --sending-pool ID       Set sending IP from pool ID

        --archive-to URL        Send copy to URL via HTTP POST

        --rm-header HEADER      Suppress X-Mailgun HEADER
    -e, --header HEADER=VAL     Add custom HEADER, set to VAL
    -x, --var VAR=VAL           Add custom variable, set to VAL
        --to-vars JSON          Per-Recipient customizations as JSON Dictionary
EOF
}

main() {
    local -a opt
    local i body_type api_key api_dom from
    body_type="text"
    api_key="${MAILGUN_API_KEY}"
    api_dom="${MAILGUN_API_DOMAIN}"
    args="$(getopt \
        --options hu:d:tHkf:s:c:b:A:a:i:T:g:e:x: \
        --longoptions help,usr:,dom:,test,html \
        --longoptions tls,dkim,dkim2:,dkim2-pub: \
        --longoptions from:,subject:,cc:,bcc:,amp:,attach:,inline: \
        --longoptions templ:,templ-ver:,templ-txt,templ-vars: \
        --longoptions tag: \
        --longoptions delay:,delay-opt:,recip-tz: \
        --longoptions track:,track-clicks:,track-opens:,track-top-pos: \
        --longoptions sending-ip:,sending-pool: \
        --longoptions archive-to: \
        --longoptions rm-header:,header:,var:,to-vars: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${args}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -u | --user )       api_key="${2}"; shift;;
            -d | --get )        api_dom="${2}"; shift;;
            -t | --test )       opt+=( -F o:testmode=yes );;
            -H | --html )       body_type="html";;
            --tls )             opt+=( -F o:require-tls=yes );;
            -k | --dkim )       opt+=( -F o:dkim=yes );;
            --dkim2 )           opt+=( -F o:secondary-dkim="${2}" ); shift;;
            --dkim2-pub )       opt+=( -F o:secondary-dkim-public="${2}" ); shift;;
            -f | --from )       from="${2}"; shift;;
            -s | --subject )    opt+=( -F subject="${2}" ); shift;;
            -c | --cc )         opt+=( -F cc="${2}" ); shift;;
            -b | --bcc )        opt+=( -F bcc="${2}" ); shift;;
            -A | --amp )        opt+=( -F amp-html="${2}" ); shift;;
            -a | --attach )     opt+=( -F attachment="@${2}" ); shift;;
            -i | --inline )     opt+=( -F inline="@${2}" ); shift;;
            -T | --templ )      opt+=( -F template="${2}" ); shift;;
            --templ-ver )       opt+=( -F t:version="${2}" ); shift;;
            --templ-var )       opt+=( -F t:variables="${2}" ); shift;;
            --templ-txt )       opt+=( -F t:text=yes );;
            -g | --tag )        opt+=( -F o:tag="${2}" ); shift;;
            --delay )           opt+=( -F o:deliverytime="${2}" ); shift;;
            --delay-opt )       opt+=( -F o:deliverytime-optimize-period="${2}" ); shift;;
            --recip-tz )        opt+=( -F o:time-zone-localize="${2}" ); shift;;
            --track )           opt+=( -F o:tracking="${2}" ); shift;;
            --track-clicks )    opt+=( -F o:tracking-clicks="${2}" ); shift;;
            --track-opens )     opt+=( -F o:tracking-opens="${2}" ); shift;;
            --track-top-pos )   opt+=( -F o:tracking-pixel-location-top="${2}" ); shift;;
            --sending-ip )      opt+=( -F o:sending-ip="${2}" ); shift;;
            --sending-pool )    opt+=( -F o:sending-ip-pool="${2}" ); shift;;
            --archive-to )      opt+=( -F o:archive-to="${2}" ); shift;;
            --remove-header )   opt+=( -F o:suppress-headers="${2}" ); shift;;
            -e | --header )     opt+=( -F h:"${2}" ); shift;;
            -x | --var )        opt+=( -F v:"${2}" ); shift;;
            --to-vars )         opt+=( -F o:recipient-variables="${2}" ); shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    [[ -z "${from}" ]] && from="${USER} <${USER}@${api_dom}>"

    mapfile -t body

    if [[ -z "${api_key}" ]]; then
        printf 'Mailgun API Key required.\n' >&2
        return 1
    elif [[ -z "${api_dom}" ]]; then
        printf 'Mailgun API Domain required.\n' >&2
        return 1
    fi

    while (( $# > 0 )); do
        opt+=( -F to="${1}" )
        shift
    done

    for i in "${body[@]}"; do
        opt+=( -F "${body_type}=${i}" )
    done

    curl \
        --silent \
        --fail \
        --include \
        --request 'POST' \
        --user "${api_key}" \
        "https://api.mailgun.net/v3/${api_dom}/messages" \
        --header 'Content-Type: multipart/form-data' \
        -F from="${from}" \
        "${opt[@]}"
}

main "${@}"
