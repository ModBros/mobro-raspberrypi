#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

if [[ $# -le 1 ]]; then
    echo "Wrong number of arguments supplied"
    exit 1
fi

# Hide the cursor (move it to the bottom-right)
xwit -root -warp $( cat /sys/module/*fb*/parameters/fbwidth ) $( cat /sys/module/*fb*/parameters/fbheight )

# Start the window manager
matchbox-window-manager -use_titlebar no -use_cursor no &

chromium-browser \
    --allow-insecure-localhost \
    --no-wifi \
    --no-default-browser-check \
    --no-service-autorun \
    --disable-infobars \
    --noerrdialogs \
    --incognito \
    --no-sandbox \
    --kiosk \
    $@
