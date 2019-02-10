#!/bin/bash

# ==========================================================
# Modbros Monitoring Service - Raspberry Pi
#
# systemd service
#
# Created with <3 in Austria by: (c) ModBros 2019
# Contact: mod-bros.com
# ==========================================================

# Files
HOSTS_FILE='/home/pi/ModbrosMonitoring/data/hosts.txt'
WIFI_FILE='/home/pi/ModbrosMonitoring/data/wifi.txt'
VERSION_FILE='/home/pi/ModbrosMonitoring/data/version.txt'
LOG_FILE='/home/pi/ModbrosMonitoring/data/log.txt'
MOBRO_FOUND_FLAG='/home/pi/ModbrosMonitoring/data/mobro_found.txt'

# URLs (local pages)
URL_NOTFOUND='http://localhost/modbros/notfound.php'
URL_HOTSPOT='http://localhost/modbros/hotspot.php'
URL_CONNECT_MOBRO='http://localhost/modbros/connecting.php'
URL_CONNECT_WIFI='http://localhost/modbros/connectwifi.php'

# Ports
MOBRO_PORT='42100'     # port of the MoBro desktop application

# Global Vars
LOOP_INTERVAL=5        # in seconds
CHECK_INTERVAL=60      # in loops (60x5=300s -> every 5 minutes)
CURR_URL=''            # to save currently active page
HOTSPOT_COUNTER=0      # counter variable for connection retry in hotspot mode
BACKGROUND_COUNTER=0   # counter variable for background alive check in wifi mode
LAST_CHECKED_SSID=''   # remember last checked wifi credentials
LAST_CHECKED_PW=''     # remember last checked wifi credentials

# versions
PI_VERSION=$(cat /proc/device-tree/model)           # pi version (e.g. Raspberry Pi 3 Model B Plus Rev 1.3)
SERVICE_VERSION=$(cat "$VERSION_FILE" | sed -n 1p)  # service version number


# =============================
# Functions
# =============================

update_pi() {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean -y
}

log() {
    echo "$(date "+%m%d%Y %T") [$1] $2" >> "$LOG_FILE"
}

sleep_short() {
    if [[ ${PI_VERSION} == *"Zero"* ]]; then
      sleep 10
    else
      sleep 2
    fi
}

sleep_long() {
    if [[ ${PI_VERSION} == *"Zero"* ]]; then
      sleep 30
    else
      sleep 15
    fi
}

show_page() {
    if [[ "$CURR_URL" != "$1" ]]; then
        log "show_page" "switching to page $1"
        CURR_URL="$1"
        sudo ./stopchrome.sh
        sleep_short
        ./startchrome.sh "$1" &
        sleep_long
        log "show_page" "done"
    fi
}

create_access_point() {
    log "create_access_point" "creating access point"
    sudo ./createaccesspoint.sh
    show_page ${URL_HOTSPOT}
    until systemctl is-active --quiet hostapd; do
        sleep 1
    done
    log "create_access_point" "done"
}

connect_wifi() {
    log "connect_wifi" "connecting to wifi: $1 $2"
    show_page ${URL_CONNECT_WIFI}
    sudo ./connectwifi.sh $1 $2
    sleep_long
    if [[ $(iwgetid) ]]; then
        log "connect_wifi" "connected"
        handle_connecting
    else
        log "connect_wifi" "not connected"
        create_access_point
    fi
}

try_ip() {
    # $1 = IP, $2 = key
    log "service_discovery" "Trying IP: $1 with key: $2"
    if [[ $(curl -o /dev/null --silent --max-time 5 --connect-timeout 1 --write-out '%{http_code}' "$1:$MOBRO_PORT/discover?key=$2") -eq 200 ]]; then
        # found MoBro application -> done
        log "service_discovery" "MoBro application found on IP $1"
        show_page "http://$1:$MOBRO_PORT?version=$SERVICE_VERSION&name=$PI_VERSION"

        # write found (use file as kind of global variable)
        # -> this function is started in a sub process!
        echo "1" > "${MOBRO_FOUND_FLAG}"

        # write to file to find it faster on next boot
        echo "$1" > "${HOSTS_FILE}"
    fi
}

service_discovery() {
    # search available IPs on the network
    log "service_discovery" "starting service discovery"

    echo "0" > "${MOBRO_FOUND_FLAG}"
    sudo arp-scan --interface=wlan0 --localnet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" >> "${HOSTS_FILE}"
    KEY=$(cat "$WIFI_FILE" | sed -n 3p)         # 3rd line contains MoBro connection key

    while read IP; do
        try_ip "$IP" "$KEY"
        if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
            # found MoBro application -> done
            break
        fi
    done < "${HOSTS_FILE}"

    # fallback -> brute force approach -> try everything in range 192.168.X.X
    if [[ $(cat "$MOBRO_FOUND_FLAG") -ne 1 ]]; then
        log "service_discovery" "using 'brute force' and just trying ips in range 192.168.X.X"
        for i in {0..255}
        do
            for j in {0..255}
            do
                try_ip "192.168.$i.$j" "$KEY" &
                pids[${j}]=$! # remember pids of started sub processes
            done

            # wait for all started checks to finish
            for pid in ${pids[*]}; do
                wait $pid
            done
            unset $pid

            # no need to continue if found
            if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
                break
            fi
        done
    fi

    if [[ $(cat "$MOBRO_FOUND_FLAG") -ne 1 ]]; then
        # couldn't find application -> delete IPs
        log "service_discovery" "no MoBro application found"
        truncate -s 0 "${HOSTS_FILE}"
        show_page ${URL_NOTFOUND}
    fi
}

handle_connecting() {
    log "handle_connecting" "start connecting"

    IP=$(cat "$HOSTS_FILE" | sed -n 1p) # get 1st host if present (from last successful connection)
    KEY=$(cat "$WIFI_FILE" | sed -n 3p)   # 3rd line contains MoBro connection key
    if ! [[ -z ${IP} || -z ${KEY} ]]; then
        try_ip "$IP" "$KEY"
        if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
            # found MoBro application -> done
            log "handle_connecting" "found previous valid host - done"
            return
        fi
    fi

    # no host or no longer valid -> start discovery
    show_page ${URL_CONNECT_MOBRO}
    service_discovery
}

hotspot_check() {
    SSID=$(cat "$WIFI_FILE" | sed -n 1p)      # 1st line contains SSID
    PW=$(cat "$WIFI_FILE" | sed -n 2p)        # 2nd line contains PW
    if ! [[ -z ${SSID} || -z ${PW} ]]; then
        if [[ ${SSID} != ${LAST_CHECKED_SSID} ]]; then
            if [[ ${PW} != ${LAST_CHECKED_PW} ]]; then
                # if there is new access data -> instantly try connecting
                LAST_CHECKED_SSID=${SSID}
                LAST_CHECKED_PW=${PW}
                log "hotspot_check" "trying to connect with $SSID and $PW"
                connect_wifi "$SSID" "$PW"
                return
            fi
        fi
    fi

    HOTSPOT_COUNTER=$((HOTSPOT_COUNTER+1))
    if [[ ${HOTSPOT_COUNTER} -ge ${CHECK_INTERVAL} ]]; then
        log "hotspot_check" "start hotspot check"
        HOTSPOT_COUNTER=0
        if ! [[ -z ${SSID} || -z ${PW} ]]; then
            # wifi configured -> try again
            log "hotspot_check" "trying to connect with $SSID and $PW"
            connect_wifi "$SSID" "$PW"
        fi
    else
        log "hotspot_check" "skipping hotspot check"
    fi
}

background_check() {
    BACKGROUND_COUNTER=$((BACKGROUND_COUNTER+1))
    if [[ ${BACKGROUND_COUNTER} -ge ${CHECK_INTERVAL} ]]; then
        log "background_check" "starting background check"
        BACKGROUND_COUNTER=0
        service_discovery
    else
        log "background_check" "skipping background check"
    fi
}


# =============================
# Startup + Main Logic Loop
# =============================

# env vars
export DISPLAY=:0

# clear log
echo '' > "$LOG_FILE"

log "Main" "starting service"

# startup delay
sleep_long

# disable blank screen
xset s off
xset -dpms
xset s noblank

# reset flag
echo "0" > "${MOBRO_FOUND_FLAG}"

# main loop
while true; do
    log "Main" "Loop start"
    if ! systemctl is-active --quiet hostapd
    then
        # no hotspot running
        log "Main" "no hotspot"
        if ! [[ $(iwgetid) ]]; then
            # not connected to wifi -> create hotspot
            log "Main" "no wifi"
            create_access_point
        else
            # connected to wifi
            log "Main" "wifi connected"
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
        log "Main" "hotspot up"

        # hotstop running -> check if chrome is up
        if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -eq 0 ]]; then
            show_page ${URL_HOTSPOT}
        fi

        # check hotspot -> if open too long, try to connect to wifi again
        hotspot_check
    fi

    log "Main" "Loop end"
    sleep ${LOOP_INTERVAL}
done

log "Main" "unexpected shutdown"

exit 1
