#!/usr/bin/env bash
#
# Toggles Redshift

if ! command -v 'redshift' &>/dev/null; then
    printf 'Missing required application: redshift\n' >&2
    return 1
fi

killall --quiet 'redshift'
while pidof 'redshift' &>/dev/null; do
    sleep 1
done
redshift -l "${1:-geoclue2}" & disown
