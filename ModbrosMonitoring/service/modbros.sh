#!/bin/bash

# ====================================================================================================================
# Modbros Monitoring Service - Raspberry Pi
#
# systemd service
#
# Created with <3 in Austria by: (c) ModBros 2019
# Contact: mod-bros.com
# ====================================================================================================================

# Files
HOSTS_FILE='/home/modbros/ModbrosMonitoring/data/hosts.txt'
WIFI_FILE='/home/modbros/ModbrosMonitoring/data/wifi.txt'
VERSION_FILE='/home/modbros/ModbrosMonitoring/data/version.txt'
UPDATED_FILE='/home/modbros/ModbrosMonitoring/data/updated.txt'
MOBRO_FOUND_FLAG='/home/modbros/ModbrosMonitoring/data/mobro_found.txt'
NETWORKS_FILE='/home/modbros/ModbrosMonitoring/data/ssids.txt'

# Resources
IMAGE_MOBRO='/home/modbros/ModbrosMonitoring/resources/mobro.png'
IMAGE_UPDATE='/home/modbros/ModbrosMonitoring/resources/update.png'
IMAGE_FOUND='/home/modbros/ModbrosMonitoring/resources/found.png'
IMAGE_NOTFOUND='/home/modbros/ModbrosMonitoring/resources/notfound.png'
IMAGE_CONNECTWIFI='/home/modbros/ModbrosMonitoring/resources/connectwifi.png'
IMAGE_DISCOVERY='/home/modbros/ModbrosMonitoring/resources/discovery.png'
IMAGE_HOTSPOT='/home/modbros/ModbrosMonitoring/resources/hotspot.png'
IMAGE_HOTSPOTCREATION='/home/modbros/ModbrosMonitoring/resources/creatinghotspot.png'
IMAGE_WIFIFAILED='/home/modbros/ModbrosMonitoring/resources/wififailed.png'
IMAGE_WIFISUCCESS='/home/modbros/ModbrosMonitoring/resources/wifisuccess.png'
IMAGE_NOWIFIINTERFACE='/home/modbros/ModbrosMonitoring/resources/nowifiinterface.png'

# Directories
LOG_DIR='/home/modbros/ModbrosMonitoring/log'

# Ports
MOBRO_PORT='42100'               # port of the MoBro desktop application

# Global Vars
AP_SSID='ModBros_Configuration'  # SSID of the created access point
AP_PW='modbros123'               # password of the created access point
LOOP_INTERVAL=5                  # in seconds
CHECK_INTERVAL_HOTSPOT=60        # in loops (60*5=300s -> every 5 minutes)
CHECK_INTERVAL_BACKGROUND=20     # in loops
UPDATE_THRESHOLD=1209600         # update/upgrade pi at least every X seconds
AP_RETRY_WAIT=20                 # how long to wait for AP to start/stop before issuing command again (in s)
AP_FAIL_WAIT=90                  # how long to wait until AP creation/stopping is considered failed -> reboot (in s)
STARTUP_WIFI_WAIT=45             # seconds to wait for wifi connection on startup (if wifi configured)
WIFI_WAIT=30                     # seconds to wait for wifi connection
HOTSPOT_COUNTER=0                # counter variable for connection retry in hotspot mode
BACKGROUND_COUNTER=0             # counter variable for background alive check in wifi mode
LAST_CHECKED_WIFI=''             # remember timestamp of last checked wifi credentials
CURR_MOBRO_URL=''                # save current MoBro Url
CURR_IMAGE=''                    # save currently displayed image
NUM_CORES=$(nproc --all)         # number of available


# versions
PI_VERSION=$(cat /proc/device-tree/model)                     # pi version (e.g. Raspberry Pi 3 Model B Plus Rev 1.3)
SERVICE_VERSION=$(cat "$VERSION_FILE" | sed -n 1p)            # service version number
PI_UUID=$(cat /sys/class/net/wlan0/address | sed 's/://g')    # unique ID of this pi

# ====================================================================================================================
# Functions
# ====================================================================================================================

log() {
    LOG_DATE=$(date "+%d.%m.%y %T");
    TEMP=$(sudo vcgencmd measure_temp)
    echo "$LOG_DATE | ${TEMP:5} : [$1] $2" >> "$LOG_DIR/log.txt"
}

wait_window() {
    until [[ $(xdotool search --onlyvisible --class "$1" | wc -l) -gt 0 ]]; do
        log "helper" "waiting for $1 to become available.."
        sleep 2
    done
}

sleep_cpu() {
    # taking the 2nd reading (1s after launching)
    # 1st one is artificially high due to launching top, especially on Pi zero
    CPU_USAGE=$(top -b -d1 -n2 | grep -i "%Cpu(s)")
    CPU_USAGE=$(echo ${CPU_USAGE} | cut -d '%' -f3 | cut -d ' ' -f2)
    until [[ $(echo "$CPU_USAGE>10.0" | bc) -eq 0 ]]; do
        log "helper" "waiting for cpu usage to come down ($CPU_USAGE)"
        sleep 5
        CPU_USAGE=$(top -b -d1 -n2 | grep -i "%Cpu(s)")
        CPU_USAGE=$(echo ${CPU_USAGE} | cut -d '%' -f3 | cut -d ' ' -f2)
    done
    log "helper" "cpu usage: $CPU_USAGE"
}

stop_process() {
    log "helper" "stopping processes: $@"
    sudo killall -TERM $@ 2>/dev/null;
}

sleep_pi() {
    if [[ ${NUM_CORES} -gt 1 ]]; then
        sleep $1
    else
        sleep $2
    fi
}

show_image() {
    if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -gt 0 ]]; then
        stop_process "chromium-browser"
        sleep_pi 1 2
    fi
    if [[ $(ps ax | grep feh | grep -v "grep" | wc -l) -gt 0 ]]; then
        if [[ "$CURR_IMAGE" == "$1" ]]; then
            # already showing requested image
            return
        fi
        stop_process "feh"
    fi
    CURR_IMAGE="$1"
    log "feh" "switching to image $1"
    feh \
        --fullscreen \
        --hide-pointer \
        --no-menus \
        --scale-down \
        --auto-zoom \
        --image-bg "white" \
        $1 &>> "$LOG_DIR/log.txt" &
    sleep_pi 0 1
}

show_mobro() {
    if [[ $(ps ax | grep chromium | grep -v "grep" | wc -l) -gt 0 ]]; then
        if [[ "$CURR_MOBRO_URL" == "$1" ]]; then
            # already showing requested page
            return
        fi
        stop_process "chromium-browser"
    fi
    show_image ${IMAGE_FOUND}
    sleep_pi 5 10
    stop_process "feh"
    CURR_MOBRO_URL="$1"
    log "chromium" "switching to MoBro application on '$1'"
    chromium-browser $1 \
        --no-default-browser-check \
        --no-service-autorun \
        --no-first-run \
        --disable-infobars \
        --disable-translate \
        --noerrdialogs \
        --incognito \
        --kiosk \
        --fast-start \
        --fast \
        --app \
        &>> "$LOG_DIR/log.txt" &
    wait_window "chromium"
}

search_ssids() {
    log "search_ssids" "scanning for wireless networks"
    sudo iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/' 2>> "$LOG_DIR/log.txt" 1> "$NETWORKS_FILE"
    log "search_ssids" "detected wifi networks in range:"
    cat "$NETWORKS_FILE" &>> "$LOG_DIR/log.txt"
}

create_access_point() {
    log "create_access_point" "creating access point"

    show_image ${IMAGE_HOTSPOTCREATION}

    # scan for available wifi networks
    # (we can't do that once we the access point is up)
    search_ssids

    # create access point
    create_access_point_call
    sleep_pi 2 5

    AP_CREATE_COUNTER=1
    AP_RETRY=$((AP_RETRY_WAIT/5))
    AP_FAIL=$((AP_FAIL_WAIT/5))
    until [[ $(create_ap --list-running | grep wlan0 | wc -l) -gt 0 ]]; do
        AP_CREATE_COUNTER=$((AP_CREATE_COUNTER+1))
        if [[ ${AP_CREATE_COUNTER} -gt ${AP_FAIL} ]]; then
            log "create_access_point" "failed to create access point multiple times - rebooting.."
            sudo shutdown -r now
        fi
        if [[ $(($AP_CREATE_COUNTER%$AP_RETRY)) -eq 0 ]]; then
            log "create_access_point" "failed to create access point - trying again"
            create_access_point_call
        fi
        log "create_access_point" "waiting for access point.."
        sleep 5
    done

    log "create_access_point" "access point up"
    show_image ${IMAGE_HOTSPOT}
}

create_access_point_call() {
    sudo create_ap \
        -w 2 \
        -m none \
        --isolate-clients \
        --freq-band 2.4 \
        --driver nl80211 \
        --no-virt \
        --daemon \
        -g 192.168.4.1 \
        wlan0 $AP_SSID $AP_PW \
        &>> "$LOG_DIR/log.txt"
}

connect_wifi() {
    log "connect_wifi" "connecting to SSID: $1"
    show_image ${IMAGE_CONNECTWIFI}

    # stop access point
    sudo create_ap --stop wlan0 &>> "$LOG_DIR/log.txt"
    sleep_pi 2 5

    AP_STOP_COUNTER=1
    AP_RETRY=$((AP_RETRY_WAIT/5))
    AP_FAIL=$((AP_FAIL_WAIT/5))
    until [[ $(create_ap --list-running | grep wlan0 | wc -l) -eq 0 ]]; do
        AP_STOP_COUNTER=$((AP_STOP_COUNTER+1))
        if [[ ${AP_STOP_COUNTER} -gt ${AP_FAIL} ]]; then
            log "connect_wifi" "failed to stop AP multiple times"
            log "connect_wifi" "resetting wpa_supplicant.conf"
            sudo cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf
            log "connect_wifi" "rebooting..."
            sudo shutdown -r now
        fi
        if [[ $((AP_STOP_COUNTER%$AP_RETRY)) -eq 0 ]]; then
            log "connect_wifi" "failed to stop AP - trying again"
            sudo create_ap --stop wlan0 &>> "$LOG_DIR/log.txt"
        fi
        log "connect_wifi" "waiting for access point to stop.."
        sleep 5
    done

    # configure wifi
    log "connect_wifi" "setting new wpa_supplicant.conf"
    sudo cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    sudo sed -i -e "s/SSID_PLACEHOLDER/$1/g" /etc/wpa_supplicant/wpa_supplicant.conf
    sudo cat /etc/wpa_supplicant/wpa_supplicant.conf &>> "$LOG_DIR/log.txt"
    sudo sed -i -e "s/PW_PLACEHOLDER/$2/g" /etc/wpa_supplicant/wpa_supplicant.conf

    log "connect_wifi" "restarting dhcpcd and networking"
    sudo systemctl restart dhcpcd.service
    sudo systemctl restart networking.service

    # wait for connection
    WIFI_CONNECT_COUNT=0
    until [[ ${WIFI_CONNECT_COUNT} -ge ${WIFI_WAIT} ]]; do
        if [[ $(iwgetid wlan0 --raw) ]]; then
            break;
        fi
        log "connect_wifi" "waiting for wifi..."
        sleep 5
        WIFI_CONNECT_COUNT=$((WIFI_CONNECT_COUNT+5))
    done

    if [[ $(iwgetid wlan0 --raw) ]]; then
        log "connect_wifi" "connected"
        show_image ${IMAGE_WIFISUCCESS}
        sleep_pi 10 10
        show_image ${IMAGE_DISCOVERY}
        service_discovery
    else
        log "connect_wifi" "not connected"
        show_image ${IMAGE_WIFIFAILED}
        sleep_pi 10 10
        create_access_point
    fi
}

try_ip() {
    # $1 = IP, $2 = key
    log "service_discovery" "Trying IP: $1 with key: $2"
    if [[ $(curl -o /dev/null --silent --max-time 5 --connect-timeout 2 --write-out '%{http_code}' "$1:$MOBRO_PORT/discover?key=$2") -eq 200 ]]; then
        # found MoBro application -> done
        log "service_discovery" "MoBro application found on IP $1"
        show_mobro "http://$1:$MOBRO_PORT?version=$SERVICE_VERSION&name=$PI_VERSION&uuid=$PI_UUID"

        # write found (use file as kind of global variable)
        # -> this function is started in a sub process!
        echo "1" > "${MOBRO_FOUND_FLAG}"

        # write to file to find it faster on next boot
        echo "$1" > "${HOSTS_FILE}"
    fi
}

service_discovery() {
    log "service_discovery" "starting service discovery"

    echo "0" > "${MOBRO_FOUND_FLAG}"

    # check previous host if configured
    IP=$(cat "$HOSTS_FILE" | sed -n 1p)   # get 1st host if present (from last successful connection)
    KEY=$(cat "$WIFI_FILE" | sed -n 3p)   # 3rd line contains MoBro connection key
    if ! [[ -z ${IP} || -z ${KEY} ]]; then
        log "service_discovery" "checking previous host"
        try_ip "$IP" "$KEY"
        if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
            # found MoBro application -> done
            return
        fi
    fi

    # search available IPs on the network
    log "service_discovery" "performing arp scan"
    sudo arp-scan --interface=wlan0 --localnet --retry=3 --timeout=500 --backoff=2 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" 2>> "$LOG_DIR/log.txt" 1>> "${HOSTS_FILE}"
    KEY=$(cat "$WIFI_FILE" | sed -n 3p)         # 3rd line contains MoBro connection key

    while read IP; do
        try_ip "$IP" "$KEY"
        if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
            # found MoBro application -> done
            return
        fi
    done < "${HOSTS_FILE}"

    # fallback: get current IP of pi to try all host in range
    log "service_discovery" "fallback"
    PI_IP=$(ifconfig wlan0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' 2>> "$LOG_DIR/log.txt")
    if ! [[ -z ${PI_IP} ]]; then
        PI_IP_1=$(echo "$PI_IP" | cut -d . -f 1)
        PI_IP_2=$(echo "$PI_IP" | cut -d . -f 2)
        PI_IP_3=$(echo "$PI_IP" | cut -d . -f 3)
        log "service_discovery" "trying all IPs in range $PI_IP_1.$PI_IP_2.$PI_IP_3.X"

        PI_IP_4=0
        while [[ ${PI_IP_4} -lt 255 ]]; do
            for j in $(seq $((4*$NUM_CORES)))
            do
                try_ip "$PI_IP_1.$PI_IP_2.$PI_IP_3.$PI_IP_4" "$KEY" &
                pids[${j}]=$! # remember pids of started sub processes
                if [[ PI_IP_4 -ge 255 ]]; then
                    break;
                fi
                PI_IP_4=$((PI_IP_4 + 1))
            done

            # wait for all started checks to finish
            for pid in ${pids[*]}; do
                wait $pid
            done
            unset $pids

            # no need to continue if found
            if [[ $(cat "$MOBRO_FOUND_FLAG") -eq 1 ]]; then
                return
            fi
        done
    fi

    if [[ $(cat "$MOBRO_FOUND_FLAG") -ne 1 ]]; then
        # couldn't find application -> delete IPs
        log "service_discovery" "no MoBro application found"
        truncate -s 0 "${HOSTS_FILE}"
        show_image ${IMAGE_NOTFOUND}
    fi
}

hotspot_check() {
    UPDATED=$(cat "$WIFI_FILE" | sed -n 4p)     # 4th line contains updated timestamp
    SSID=$(cat "$WIFI_FILE" | sed -n 1p)        # 1st line contains SSID
    PW=$(cat "$WIFI_FILE" | sed -n 2p)          # 2nd line contains PW
    if ! [[ -z ${UPDATED} ]]; then
        if [[ ${UPDATED} != ${LAST_CHECKED_WIFI} ]]; then
            if ! [[ -z ${SSID} || -z ${PW} ]]; then
                # if there is new access data -> instantly try connecting
                LAST_CHECKED_WIFI=${UPDATED}
                HOTSPOT_COUNTER=0
                log "hotspot_check" "new credentials found. trying to connect to SSID $SSID"
                connect_wifi "$SSID" "$PW"
                return
            fi
        fi
    fi

    HOTSPOT_COUNTER=$((HOTSPOT_COUNTER+1))
    if [[ ${HOTSPOT_COUNTER} -ge ${CHECK_INTERVAL_HOTSPOT} ]]; then
        log "hotspot_check" "start hotspot check"
        HOTSPOT_COUNTER=0
        if ! [[ -z ${SSID} || -z ${PW} ]]; then
            # wifi configured -> try again
            log "hotspot_check" "trying again to connect with $SSID and $PW"
            connect_wifi "$SSID" "$PW"
        fi
    fi
}

background_check() {
    BACKGROUND_COUNTER=$((BACKGROUND_COUNTER+1))
    if [[ ${BACKGROUND_COUNTER} -ge ${CHECK_INTERVAL_BACKGROUND} ]]; then
        log "background_check" "starting background check"
        BACKGROUND_COUNTER=0
        if [[ $(cat "$MOBRO_FOUND_FLAG") -ne 1 ]]; then
            show_image ${IMAGE_DISCOVERY}
        fi
        service_discovery
    fi
}

update() {
    log "update" "performing update check"
    LAST_UPDATE_DATE=$(cat "$UPDATED_FILE" | sed -n 1p)
    CURR_DATE=$(date "+%s")
    if ! [[ -z ${LAST_UPDATE_DATE} ]]; then
        # skip if it was updated recently
        if [[ $(expr ${CURR_DATE} - ${LAST_UPDATE_DATE}) -le ${UPDATE_THRESHOLD} ]]; then
            log "update" "skipping update (last update below threshold)"
            return
        fi
    fi
    wget -q --spider http://google.com
    if [[ $? -ne 0 ]]; then
        log "update" "skipping update (no internet)"
        return
    fi
    log "update" "starting update/upgrade"
    show_image ${IMAGE_UPDATE}
    sudo apt-get update &>> "$LOG_DIR/log.txt"
    sudo apt-get upgrade -q -y &>> "$LOG_DIR/log.txt"
    sudo apt-get autoremove -y &>> "$LOG_DIR/log.txt"
    echo "$CURR_DATE" > "${UPDATED_FILE}"
    log "update" "upgrade done"
}

initial_wifi_check() {
    # check if wifi is configured
    # (skip if no network set - e.g. first boot)
    if [[ $(cat "$WIFI_FILE" | wc -l) -lt 4 ]]; then
        log "Startup" "no previous network configuration found"
        create_access_point
        return
    fi

    show_image ${IMAGE_CONNECTWIFI}
    # check if configured network is in range
    log "Startup" "scanning for wireless networks"
    search_ssids
    WAIT_WIFI=1
    if [[ $(cat "$NETWORKS_FILE" | wc -l) -ge 1 ]]; then # check if scan returned anything first
        SSID=$(cat "$WIFI_FILE" | sed -n 1p) # SSID of configured network
        if [[ $(cat "$NETWORKS_FILE" | grep "$SSID" | wc -l) -eq 0 ]]; then
            WAIT_WIFI=0
        fi
    fi

    # we need to set the global variable to indicate we tried this network
    LAST_CHECKED_WIFI=$(cat "$WIFI_FILE" | sed -n 4p) # 4th line contains updated timestamp

    if [[ ${WAIT_WIFI} -ne 1 ]]; then
        # previous wifi not reachable
        log "Startup" "configured wifi network not in range"
        show_image ${IMAGE_WIFIFAILED}
        create_access_point
        return
    fi

    log "Startup" "waiting for wifi connection..."
    WIFI_CONNECTED=0
    WIFI_CONNECT_COUNT=0
    until [[ ${WIFI_CONNECT_COUNT} -ge ${STARTUP_WIFI_WAIT} ]]; do
        if [[ $(iwgetid wlan0 --raw) ]]; then
            WIFI_CONNECTED=1
            break;
        fi
        sleep 5
        WIFI_CONNECT_COUNT=$((WIFI_CONNECT_COUNT+5))
    done

    if [[ ${WIFI_CONNECTED} -ne 1 ]]; then
        log "Startup" "couldn't connect to wifi"
        show_image ${IMAGE_WIFIFAILED}
        create_access_point
        return
    fi

    log "Startup" "connected to wifi"
    show_image ${IMAGE_WIFISUCCESS}
    sleep_pi 2 2

    # search network for application
    show_image ${IMAGE_DISCOVERY}
    sleep_pi 2 2
    service_discovery
}

# ====================================================================================================================
# Startup Sequence
# ====================================================================================================================

# copy log files to preserve the previous 10 starts

for i in {8..0}
do
    mv -f "$LOG_DIR/log_$i.txt" "$LOG_DIR/log_$(expr ${i} + 1).txt" 2>/dev/null
done
cp -f "$LOG_DIR/log.txt" "$LOG_DIR/log_0.txt" 2>/dev/null

# clear current log
echo '' > "$LOG_DIR/log.txt"

log "Startup" "starting service"

# env vars
export DISPLAY=:0

# reset flag
echo "0" > "${MOBRO_FOUND_FLAG}"

# disable dnsmasq and hostapd
log "Startup" "disabling services: dnsmasq, hostapd"
sudo systemctl stop dnsmasq &>> "$LOG_DIR/log.txt"
sudo systemctl disable dnsmasq.service &>> "$LOG_DIR/log.txt"
sudo systemctl stop hostapd &>> "$LOG_DIR/log.txt"
sudo systemctl disable hostapd.service &>> "$LOG_DIR/log.txt"

# start x
log "Startup" "starting x server"
sudo xinit \
    /bin/sh -c "exec /usr/bin/matchbox-window-manager -use_titlebar no -use_cursor no" \
    -- -nocursor \
    &>> "$LOG_DIR/log.txt" &

# show background
show_image $IMAGE_MOBRO

# disabling screen blanking
log "Startup" "disable blank screen"
{
  sudo xset s off
  sudo xset -dpms
  sudo xset s noblank
} &>> "$LOG_DIR/log.txt"

# start webserver
log "Startup" "starting lighttpd"
sudo systemctl start lighttpd &>> "$LOG_DIR/log.txt"

# wait for CPU usage to come down
sleep_cpu
sleep_pi 5 5

# check for wifi interface
if [[ $(ifconfig | grep wlan | wc -l) -lt 1 ]]; then
    log "Startup" "no wifi interface detected, aborting"
    show_image ${IMAGE_NOWIFIINTERFACE}
    while true; do
        sleep 60
    done
fi

# try to connect to wifi (if previously configured)
# and try to connect to mobro
initial_wifi_check

# ====================================================================================================================
# Main Loop
# ====================================================================================================================

log "Main" "Entering main loop"
LOOP_COUNTER=0
while true; do
    if [[ $((LOOP_COUNTER%10)) -eq 0 ]]; then
        log "Main" "loop $LOOP_COUNTER"
    fi
    if [[ $(create_ap --list-running | grep wlan0 | wc -l) -eq 0 ]]; then
        # no hotspot running
        if ! [[ $(iwgetid wlan0 --raw) ]]; then
            create_access_point
        else
            # we're connected - keep checking in background (page still response / page becomes available)
            background_check
        fi
    else
        # check for new wifi data + if hotspot open too long, try to connect to wifi again
        hotspot_check
    fi
    sleep ${LOOP_INTERVAL}
    LOOP_COUNTER=$((LOOP_COUNTER+1))
done

log "Main" "unexpected shutdown"
