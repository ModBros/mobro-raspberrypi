#!/bin/bash

# ==========================================================
# Modbros Monitoring Service - Raspberry Pi
#
# Created with <3 in Austria by: (c) ModBros 2019
# Contact: mod-bros.com
# ==========================================================

# Files
HOSTS_FILE='/home/pi/ModbrosMonitoring/data/hosts.txt'
WIFI_FILE='/home/pi/ModbrosMonitoring/data/wifi.txt'
VERSION_FILE='/home/pi/ModbrosMonitoring/data/version.txt'

# URLs
URL_NOTFOUND='http://localhost/modbros/notfound.php'
URL_HOTSPOT='http://localhost/modbros/hotspot.php'
URL_CONNECTING='http://localhost/modbros/connecting.php'
MOBRO_PORT='42100'

# Global Vars
CURR_URL=''

# =============================
# Functions
# =============================

update_pi () {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean -y
}

show_page() {
    if [[ "$CURR_URL" != "$1" ]]; then
        CURR_URL="$1"
        ./stopchrome.sh
        DISPLAY=:0 ./startchrome.sh $1 &
    fi
}

create_access_point () {
    sudo ./createaccesspoint.sh
    show_page ${URL_HOTSPOT}
    until systemctl is-active --quiet hostapd; do
        sleep 1
    done
}

handle_connecting () {
    show_page http://localhost/modbros/connecting.php

    # search available IPs on the network
    FOUND=0
    sudo arp-scan --interface=wlan0 --localnet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" >> "${HOSTS_FILE}"
    KEY=$(cat "$WIFI_FILE" | sed -n 3p)         # 3rd line contains MoBro connection key
    VERSION=$(cat "$VERSION_FILE" | sed -n 1p)  # service version number
    PI_VERSION=$(cat /proc/device-tree/model)   # pi version (e.g. Raspberry Pi 3 Model B Plus Rev 1.3)
    while read IP; do
        echo "Trying IP: $IP with key: $KEY"
        if [[ $(curl -o /dev/null --silent --write-out '%{http_code}' "$IP:$MOBRO_PORT/discover?key=$KEY") -eq 200 ]]; then
            # found MoBro application -> done
            echo "MoBro application found"
            show_page "$IP:$MOBRO_PORT?version=$VERSION&name=$PI_VERSION"
            FOUND=1

            # write to file to find it faster on next boot
            echo "$IP" > "${HOSTS_FILE}"
            break
        fi
        sleep 1
    done < "${HOSTS_FILE}"

    if [[ ${FOUND} -ne 1 ]]; then
        # couldn't find application -> delete IPs
        echo "No MoBro found"
        truncate -s 0 "${HOSTS_FILE}"
        show_page ${URL_NOTFOUND}
    fi
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
            show_page ${URL_HOTSPOT}
        fi
    fi

    sleep 5 # TODO
done

exit 1
