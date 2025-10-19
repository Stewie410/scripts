#!/usr/bin/env bash

docker run \
    --interactive \
    --tty \
    --rm \
    'python:latest' \
    "${@}"
