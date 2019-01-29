#!/bin/bash

# ==========================================================
# Modbros Monitoring Service - Raspberry Pi
# TODO explanation stuff
# ==========================================================


MIKE_URL='http://192.168.8.170'
FAKE_DISCOVERY_TIME=10


# =============================
# Functions
# =============================

update_pi () {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean -y
}

start_chrome() {
#    local sc_path=$(realpath ./startchrome.sh)
#    runusr -l pi -c "$sc_path $1"
    DISPLAY=:0 ./startchrome.sh $1 &
}

create_access_point () {
    sudo ./createaccesspoint.sh
    sudo ./stopchrome.sh
    start_chrome http://localhost/modbros/hotspot.php
    until systemctl is-active --quiet hostapd; do
        sleep 1
    done
}

handle_connecting () {
    ./stopchrome.sh
    start_chrome http://localhost/modbros/connecting.php

    # TODO network discovery
    # TODO read connection key from file to ping

    sleep ${FAKE_DISCOVERY_TIME}

    COUNTER=0
    while [[ $(curl -o /dev/null --silent --write-out '%{http_code}' localhost/modbros/notfound.php) -ne 200 ]]; do
        let COUNTER+=1
        if [[ ${COUNTER} -eq 10 ]]; then
            ./stopchrome.sh
            start_chrome http://localhost/modbros/notfound.php
        fi
        echo "website not reachable"
        sleep 5
    done
    start_chrome ${MIKE_URL}
}

# =============================
# Main Logic
# =============================

sleep 30    # startup delay
#update_pi   # make sure everything is up to date

while true; do

    if ! systemctl is-active --quiet hostapd
    then
        # no hotspot running
        echo "no hotspot running"

        if ! [[ $(iwgetid) ]]; then
            # not connected to wifi -> create hotspot
            echo "not connected to wifi"
            create_access_point
        else
            # connected to wifi
            if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
                # chrome not yet running -> check website availability + connect
                handle_connecting
            fi
            # TODO fix bug
            # else: we're connected and showing a page -> done
        fi
    else
        # hotstop running -> check if chrome is up
        if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
            start_chrome http://localhost/modbros/hotspot.php
        fi
    fi

    sleep 5 # TODO
done

exit 1
