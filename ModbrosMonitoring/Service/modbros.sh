#!/bin/bash

# TODO

update_pi () {
    apt-get update
    apt-get upgrade -y
    apt-get autoremove --purge -y
    apt-get autoclean -y
}

sleep 20    # startup delay
#update_pi   # make sure everything is up to date

while true; do

    if ! systemctl is-active --quiet hostapd
    then
        # no hotspot running
        echo "no hotspot running"

        if ! [[ $(iwgetid) ]]; then
            # not connected to wifi -> create hotspot
            echo "not connected to wifi"

            ./createaccesspoint.sh

            ./stopchrome.sh
            ./startchrome.sh http://localhost/modbros/hotspot.php

             sleep 60

            continue
        else
            # connected to wifi
            if [[ $(ps a | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
                # chrome not yet running -> check website availability
                # TODO network discovery
                # TODO read connection key from file to ping
                while [[ $(curl -o /dev/null --silent --write-out '%{http_code}' localhost/modbros/notfound.php) -ne 200 ]]; do
                    echo "website not reachable"
                    sleep 5
                done
                ./startcrome.sh http://localhost
            fi
        fi
    else
    # hotstop running -> check if chrome is up
        if [[ $(ps a | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
            ./startchrome.sh http://localhost/modbros/hotspot.php
        fi
    fi

    sleep 60
done

exit 1
