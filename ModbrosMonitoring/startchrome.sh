#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Wrong number of arguments supplied"
    exit 1
fi

chromium-browser --kiosk $1

exit 0
