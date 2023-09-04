#!/usr/bin/env bash
#
# Mount/Unmount devices

show_help() {
    cat << EOF
Mount/Unmount devices

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --dmenu     Select device & mountpoint with dmenu(1)
    -r, --rofi      Select device & mountpoint with rofi(1)
    -f, --fzf       Select device & mountpoint with fzf(1) (default)
    -z, --zenity    Select device & mountpoint with zenity(1)
    -m, --mount     Mount a device (default)
    -u, --unmount   Unmount a device
    -n, --notify    Send a desktop notification with operation status
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

notify() {
    notify-send --urgency="${1}" "${2}"
}

get_fstab() {
    local uuid
    uuid="$(blkid | awk --assign "dev=${1}" '
        match($1, dev) {
            print gensub(/^.*="|"$/, "", "G", $2)
        }
    ')"

    awk --assign "dev=${1}" --assign "uuid=${uuid}" '
        match($1, dev) || (length(uuid) > 0 && match($1, "uuid=" uuid)) {
            print $2
            exit 0
        }
        END {
            exit 1
        }
    ' '/etc/fstab'
}

get_devices() {
    lsblk --list --paths | sed '1d;s/\s\+/,/g'
}

confirm() {
    local reply p
    p="Create Directory: '${1}'?: "

    case "${selector}" in
        dmenu )
            reply="$(printf 'Yes\nNo\n' | dmenu -i -p "${p}")"
            ;;
        rofi )
            reply="$(printf 'Yes\nNo\n' | rofi -dmenu -p "${p}")"
            ;;
        fzf )
            reply="$(printf 'Yes\nNo\n' | fzf -i --no-multi --prompt "${p}")"
            ;;
        zenity )
            zenity --question --title="Confirm" --text="${p:0:-2}" && \
                reply="yes"
            ;;
    esac

    reply="${reply:-no}"
    [[ "${reply,,}" == "yes" ]] && return 0
    return 1
}

get_mount_point() {
    local -a list
    get_fstab "${1}" && return 0

    mapfile -t list < <(find '/mnt' '/media' '/mount' "${HOME}" -type d)
    if (( ${#list[@]} == 0 )); then
        printf 'No potential mount points\n' >&2
        return 1
    fi

    case "${selector}" in
        dmenu )
            printf '%s\n' "${list[@]}" | dmenu -i -p "Mount Point: "
            ;;
        rofi )
            printf '%s\n' "${list[@]}" | rofi -dmenu -p "Mount Point: "
            ;;
        fzf )
            printf '%s\n' "${list[@]}" | \
                fzf -i --no-multi --prompt "Mount Point: "
            ;;
        zentiy )
            printf '%s\n' "${list[@]}" | \
                zenity --list --title="Mount Point" --column="Directory"
            ;;
    esac
}

get_unmounted_device() {
    local -a list
    mapfile -t list < <(get_devices | awk --field-separator "," '
        length($NF) > 0 {
            print $1
        }
    ')

    if (( ${#list[@]} == 0 )); then
        printf 'No unmounted devices\n' >&2
        return 1
    fi

    case "${selector}" in
        dmenu )
            printf '%s\n' "${list[@]}" | dmenu -i -p "Device: "
            ;;
        rofi )
            printf '%s\n' "${list[@]}" | rofi -dmenu -p "Device: "
            ;;
        fzf )
            printf '%s\n' "${list[@]}" | fzf -i --no-multi --prompt "Device: "
            ;;
        zenity )
            printf '%s\n' "${list[@]}" | \
                zenity --list --title="Device" --column="Block Device"
            ;;
    esac
}

get_mounted_device() {
    local -a list
    mapfile -t list < <(get_devices | awk --field-separator "," '
        length($NF) > 0 && $NF !~ /(boot|swap|distro)/ {
            print $1, "(" $NF ")"
        }
    ')

    if (( ${#list[@]} == 0 )); then
        printf 'No mounted devices\n' >&2
        return 1
    fi

    case "${selector}" in
        dmenu )
            printf '%s\n' "${list[@]}" | dmenu -i -p "Device: "
            ;;
        rofi )
            printf '%s\n' "${list[@]}" | rofi -dmenu -p "Device: "
            ;;
        fzf )
            printf '%s\n' "${list[@]}" | fzf -i --no-multi --prompt "Device: "
            ;;
        zenity )
            printf '%s\n' "${list[@]}" | \
                zenity --list --title="Device" --column="Block Device"
            ;;
    esac
}

mount_device() {
    local dev point
    dev="$(get_unmounted_device)" || return 1
    [[ -z "${dev}" ]] && return 1

    point="$(get_mount_point "${dev}")" || return 1
    if ! [[ -d "${point}" ]]; then
        confirm "${point}" || return 1
        mkdir --parents "${point}"
    fi

    if ! mount "${dev}" "${point}" &>/dev/null; then
        [[ -n "${notify}" ]] && \
            notify "critical" "Failed to mount: ${dev} -> ${point}"
        printf 'Failed to mount device: %s -> %s\n' "${dev}" "${point}" >&2
        return 1
    fi

    [[ -n "${notify}" ]] && \
        notify "normal" "Mounted: ${dev} -> ${point}"
    return 0
}

unmount_device() {
    local dev
    dev="$(get_mounted_device)" || return 1
    [[ -z "${dev}" ]] && return 1
    dev="${dev%% *}"

    if ! umount "${dev}" &>/dev/null; then
        [[ -n "${notify}" ]] && \
            notify "critical" "Failed to unmount: ${dev}"
        printf 'Failed to unmount device: %s\n' "${dev}" >&2
        return 1
    fi

    [[ -n "${notify}" ]] && \
        notify "normal" "Unmounted: ${dev}"
    return 0
}

main() {
    local opts selector notify unmount
    opts="$(getopt \
        --options hdrfzmun \
        --longoptions help,dmenu,rofi,fzf,zenity,mount,unmount,notify \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    selector="fzf"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      selector="dmenu";;
            -r | --rofi )       selector="rofi";;
            -f | --fzf )        selector="fzf";;
            -z | --zenity )     selector="zentiy";;
            -m | --mount )      unset unmount;;
            -u | --unmount )    unmount="1";;
            -n | --notify )     notify="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if (( EUID != 0 )); then
        printf 'Requires root priviledges\n' >&2
        return 1
    fi

    require "${selector}" || return 1
    ( [[ -n "${notify}" ]] && ! require 'notify-send' ) && return 1

    if [[ -n "${unmount}" ]]; then
        unmount_device || return 1
    else
        mount_device || return 1
    fi

    return 0
}

main "${@}"
