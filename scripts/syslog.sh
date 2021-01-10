#!/bin/bash

if [ $# -eq 0 ]; then
    sudo cat /var/log/syslog
else
    sudo tail -n"$1" /var/log/syslog
fi
