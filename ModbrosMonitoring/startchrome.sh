#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Wrong number of arguments supplied"
    exit 1
fi

chromium-browser \
    --kiosk \
    --no-wifi \
    --no-default-browser-check \
    --no-service-autorun \
    --allow-insecure-localhost \
    --noerrdialogs \
    --disable-infobars \
    --app=$1

exit 0
