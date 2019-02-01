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
URL_CONNECT_MOBRO='http://localhost/modbros/connecting.php'
URL_CONNECT_WIFI='http://localhost/modbros/connectwifi.php'

# Ports
MOBRO_PORT='42100'

# Global Vars
STARTUP_DELAY=30  # in seconds
LOOP_INTERVAL=5   # in seconds
CHECK_INTERVAL=30 # in loops (30x5=150s -> every 2.5 minutes)
CURR_URL=''
HOTSPOT_COUNTER=0
BACKGROUND_COUNTER=0

# =============================
# Functions
# =============================

update_pi() {
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

create_access_point() {
    sudo ./createaccesspoint.sh
    show_page ${URL_HOTSPOT}
    until systemctl is-active --quiet hostapd; do
        sleep 1
    done
}

connect_wifi() {
    show_page ${URL_CONNECT_WIFI}
    ./connectwifi.sh $1 $2
}

service_discovery() {
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

handle_connecting() {
    show_page ${URL_CONNECT_MOBRO}
    service_discovery
}

hotspot_check() {
    HOTSPOT_COUNTER=$((HOTSPOT_COUNTER+1))
    if [[ ${HOTSPOT_COUNTER} -ge 20 ]]; then
        HOTSPOT_COUNTER=0
        SSID=$(cat "$WIFI_FILE" | sed -n 1p)      # 1st line contains SSID
        PW=$(cat "$WIFI_FILE" | sed -n 2p)        # 2nd line contains PW
        if ! [[ -z ${SSID} || -z ${PW} ]]; then
            # wifi configured -> try again
            echo "trying again to connect to $SSID"
            connect_wifi "$SSID" "$PW"
            sleep 15
        fi
    fi
}

background_check() {
    BACKGROUND_COUNTER=$((BACKGROUND_COUNTER+1))
    if [[ ${BACKGROUND_COUNTER} -ge 20 ]]; then
        BACKGROUND_COUNTER=0
        echo "running service discovery again"
        service_discovery
    fi
}


# =============================
# Main Logic Loop
# =============================

sleep ${STARTUP_DELAY}    # startup delay
#update_pi   # make sure everything is up to date

while true; do

    if ! systemctl is-active --quiet hostapd
    then
        # no hotspot running

        if ! [[ $(iwgetid) ]]; then
            # not connected to wifi -> create hotspot
            create_access_point
        else
            # connected to wifi

            if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
                # chrome not yet running -> check website availability + connect
                handle_connecting
            else

                # we're connected and showing a page
                # keep checking in background (page still response / page becomes available)
                background_check
            fi
        fi
    else
        # hotstop running -> check if chrome is up
        if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
            show_page ${URL_HOTSPOT}
        fi

        # check hotspot -> if open too long, try to connect to wifi again
        hotspot_check
    fi

    sleep ${LOOP_INTERVAL}
done

exit 1
