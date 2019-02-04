#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

pkill -o chromium

exit 0
