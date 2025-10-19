#!/usr/bin/env bash

docker run \
    --interactive \
    --tty \
    --rm \
    --volume "${PWD}:/home/debian/src" \
    --publish "${D2_PORT:-8080}:8080" \
    --name "d2lang" \
    'terrastruct/d2:latest' \
    "${@}"
