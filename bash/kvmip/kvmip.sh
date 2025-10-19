#!/usr/bin/env bash
#
# Retrieve a VM's IP addr from virsh & arp

show_help() {
    cat << EOF
Retrieve KVM IP addr from virsh & arp
If no domain(s) specified, retrieve all

USAGE: ${0##*/} [OPTIONS] [DOMAIN [...]]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

vm_exists() {
    virsh list --name | grep --quiet "${1}" && return 0
    printf 'VM does not exist: %s\n' "${1}" >&2
    return 1
}

get_all_doms() {
    virsh list --name --all | \
        sed '/^\s*$/d' | \
        paste --serial --delimiters=" "
}

get_mac() {
    virsh dumpxml "${1}" | \
        sed --quiet '/mac address/p' | \
        cut --fields="2" --delimiter="'" | \
        paste --serial --delimiters='|'
}

get_networks() {
    virsh net-list | \
        awk '/active/ { print $1 }' | \
        xargs -I {} virsh net-dhcp-elases "{}"
}

get_ip() {
    arp -an | grep --extended-regexp "$(get_mac "${1}")"
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    require "virsh" || return 1
    require "arp" || return 1

    [[ -z "${1}" ]] && eval set -- "$(get_all_doms)"

    get_networks
    printf '\n'
    while (( $# > 0 )); do
        if vm_exists "${1}"; then
            printf '%s:\n' "${1}"
            get_ip "${1}"
            printf '\n'
        fi
        shift
    done
}

main "${@}"
