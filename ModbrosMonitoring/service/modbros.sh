#!/bin/bash

# ====================================================================================================================
# Modbros Monitoring Service - Raspberry Pi
#
# systemd service
#
# Created with <3 in Austria by: (c) ModBros 2020
# Contact: mod-bros.com
# ====================================================================================================================

# Directories
LOG_DIR='/home/modbros/ModbrosMonitoring/log'
RESOURCES_DIR='/home/modbros/ModbrosMonitoring/resources'
DATA_DIR='/home/modbros/ModbrosMonitoring/data'

# Files
HOSTS_FILE="$DATA_DIR/hosts"
WIFI_FILE="$DATA_DIR/wifi"
VERSION_FILE="$DATA_DIR/version"
MOBRO_FOUND_FLAG="$DATA_DIR/mobro_found"
NETWORKS_FILE="$DATA_DIR/ssids"
DISCOVERY_KEY="$DATA_DIR/discovery_key"
LOG_FILE="$LOG_DIR/log.txt"

# Resources
IMAGE_MOBRO="$RESOURCES_DIR/mobro.png"
IMAGE_FOUND="$RESOURCES_DIR/found.png"
IMAGE_NOTFOUND="$RESOURCES_DIR/notfound.png"
IMAGE_CONNECTWIFI="$RESOURCES_DIR/connectwifi.png"
IMAGE_DISCOVERY="$RESOURCES_DIR/discovery.png"
IMAGE_HOTSPOT="$RESOURCES_DIR/hotspot.png"
IMAGE_HOTSPOTCREATION="$RESOURCES_DIR/creatinghotspot.png"
IMAGE_WIFIFAILED="$RESOURCES_DIR/wififailed.png"
IMAGE_WIFISUCCESS="$RESOURCES_DIR/wifisuccess.png"
IMAGE_NOWIFIINTERFACE="$RESOURCES_DIR/nowifiinterface.png"
IMAGE_ETHSUCCESS="$RESOURCES_DIR/ethsuccess.png"

# Ports
MOBRO_PORT='42100'              # port of the MoBro desktop application

# Global Constants
AP_SSID='ModBros_Configuration' # ssid of the created access point
AP_PW='modbros123'              # password of the created access point
LOOP_INTERVAL=5                 # in seconds
CHECK_INTERVAL_HOTSPOT=60       # in loops (60*5=300s -> every 5 minutes)
CHECK_INTERVAL_BACKGROUND=20    # in loops
AP_RETRY_WAIT=20                # how long to wait for AP to start/stop before issuing command again (in s)
AP_FAIL_WAIT=90                 # how long to wait until AP creation/stopping is considered failed -> reboot (in s)
STARTUP_WIFI_WAIT=45            # seconds to wait for wifi connection on startup (if wifi configured)
WIFI_WAIT=30                    # seconds to wait for wifi connection

# Global Vars
LOOP_COUNTER=0       # counter variable for main loop iterations
HOTSPOT_COUNTER=0    # counter variable for connection retry in hotspot mode
BACKGROUND_COUNTER=0 # counter variable for background alive check in wifi mode
LAST_CHECKED_WIFI='' # remember timestamp of last checked wifi credentials
LAST_CHECKED_KEY=''  # remember timestamp of last checked discovery key
CURR_MOBRO_URL=''    # save current MoBro Url
CURR_IMAGE=''        # save currently displayed image
NETWORK_MODE=''      # save current netowrk mode (eth|wifi)

# ====================================================================================================================
# Functions
# ====================================================================================================================

log() {
    local temp date
    temp=$(sudo vcgencmd measure_temp)
    date=$(date "+%d.%m.%y %T")
    echo "$date | ${temp:5} : [$1] $2" >>$LOG_FILE
}

wait_window() {
    until [[ $(xdotool search --onlyvisible --class "$1" | wc -l) -gt 0 ]]; do
        log "helper" "waiting for $1 to become available.."
        sleep 3
    done
}

stop_process() {
    log "helper" "stopping process: $1"
    sudo pkill "$1" 2>>$LOG_FILE
    for i in {4..0}; do
        if [[ $(pgrep -fc "$1") -eq 0 ]]; then
            return
        fi
        sleep 2
    done
    log "helper" "killing process: $1"
    sudo pkill -9 "$1" 2>>$LOG_FILE
    sleep_pi 1 2
}

sleep_pi() {
    if [[ $(nproc --all) -gt 1 ]]; then
        sleep "$1"
    else
        sleep "$2"
    fi
}

show_image() {
    if [[ $(pgrep -fc chromium) -gt 0 ]]; then
        stop_process "chromium-browser"
        sleep_pi 1 2
    fi
    if [[ $(pgrep -fc feh) -gt 0 ]]; then
        if [[ $CURR_IMAGE == "$1" ]]; then
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
        "$1" &>>$LOG_FILE &

    sleep "${2:-1}"
}

show_mobro() {
    if [[ $(pgrep -fc chromium) -gt 0 ]]; then
        if [[ $CURR_MOBRO_URL == "$1" ]]; then
            # already showing requested page
            return
        fi
        stop_process "chromium-browser"
    fi
    show_image $IMAGE_FOUND 5
    stop_process "feh"
    CURR_MOBRO_URL="$1"
    log "chromium" "switching to MoBro application on '$1'"
    chromium-browser "$1" \
        --no-default-browser-check \
        --no-first-run \
        --noerrdialogs \
        --incognito \
        --use-gl=swiftshader \
        --kiosk \
        &>>$LOG_FILE &
    wait_window "chromium"
}

search_ssids() {
    log "search_ssids" "scanning for wireless networks"
    sudo iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/' 2>>$LOG_FILE 1>$NETWORKS_FILE
    log "search_ssids" "detected wifi networks in range:"
    cat $NETWORKS_FILE &>>$LOG_FILE
}

create_access_point() {
    log "create_access_point" "creating access point"

    show_image $IMAGE_HOTSPOTCREATION

    # scan for available wifi networks
    # (we can't do that once we the access point is up)
    search_ssids

    # create access point
    create_access_point_call
    sleep_pi 2 5

    local ap_create_counter ap_retry ap_fail
    ap_create_counter=1
    ap_retry=$((AP_RETRY_WAIT / 5))
    ap_fail=$((AP_FAIL_WAIT / 5))
    until [[ $(create_ap --list-running | grep -c wlan0) -gt 0 ]]; do
        ap_create_counter=$((ap_create_counter + 1))
        if [[ $ap_create_counter -gt $ap_fail ]]; then
            log "create_access_point" "failed to create access point multiple times - rebooting.."
            sudo shutdown -r now
        fi
        if [[ $((ap_create_counter % ap_retry)) -eq 0 ]]; then
            log "create_access_point" "failed to create access point - trying again"
            create_access_point_call
        fi
        log "create_access_point" "waiting for access point.."
        sleep 5
    done

    log "create_access_point" "access point up"
    show_image $IMAGE_HOTSPOT
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
        &>>$LOG_FILE
}

connect_wifi() {
    log "connect_wifi" "connecting to ssid: $1"
    show_image $IMAGE_CONNECTWIFI

    # stop access point
    sudo create_ap --stop wlan0 &>>$LOG_FILE
    sleep_pi 2 5

    local ap_stop_counter ap_retry ap_fail
    ap_stop_counter=1
    ap_retry=$((AP_RETRY_WAIT / 5))
    ap_fail=$((AP_FAIL_WAIT / 5))
    until [[ $(create_ap --list-running | grep wlan0 -c) -eq 0 ]]; do
        ap_stop_counter=$((ap_stop_counter + 1))
        if [[ $ap_stop_counter -gt $ap_fail ]]; then
            log "connect_wifi" "failed to stop AP multiple times"
            log "connect_wifi" "resetting wpa_supplicant.conf"
            sudo cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf
            log "connect_wifi" "rebooting..."
            sudo shutdown -r now
        fi
        if [[ $((ap_stop_counter % ap_retry)) -eq 0 ]]; then
            log "connect_wifi" "failed to stop AP - trying again"
            sudo create_ap --stop wlan0 &>>$LOG_FILE
        fi
        log "connect_wifi" "waiting for access point to stop.."
        sleep 5
    done

    # configure wifi
    log "connect_wifi" "setting new wpa_supplicant.conf"
    sudo cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    sudo sed -i -e "s/SSID_PLACEHOLDER/$1/g" /etc/wpa_supplicant/wpa_supplicant.conf
    sudo cat /etc/wpa_supplicant/wpa_supplicant.conf &>>$LOG_FILE
    sudo sed -i -e "s/PW_PLACEHOLDER/$2/g" /etc/wpa_supplicant/wpa_supplicant.conf

    log "connect_wifi" "restarting dhcpcd and networking"
    sudo systemctl restart dhcpcd.service
    sudo systemctl restart networking.service

    # wait for connection
    local wifi_connect_count
    wifi_connect_count=0
    until [[ $wifi_connect_count -ge $WIFI_WAIT ]]; do
        if [[ $(iwgetid wlan0 --raw) ]]; then
            break
        fi
        log "connect_wifi" "waiting for wifi..."
        sleep 5
        wifi_connect_count=$((wifi_connect_count + 5))
    done

    if [[ $(iwgetid wlan0 --raw) ]]; then
        log "connect_wifi" "connected"
        show_image $IMAGE_WIFISUCCESS 10
        show_image $IMAGE_DISCOVERY
        service_discovery
    else
        log "connect_wifi" "not connected"
        show_image $IMAGE_WIFIFAILED 10
        create_access_point
    fi
}

try_ip() {
    # $1 = IP, $2 = key
    log "service_discovery" "Trying IP: $1 with key: $2"
    if [[ $(curl -o /dev/null --silent --max-time 5 --connect-timeout 2 --write-out '%{http_code}' "$1:$MOBRO_PORT/discover?key=$2") -eq 200 ]]; then
        # found MoBro application -> done
        log "service_discovery" "MoBro application found on IP $1"
        local name version uuid
        name=$(cat /proc/device-tree/model)                # pi version name (e.g. Raspberry Pi 3 Model B Plus Rev 1.3)
        version=$(sed -n 1p <$VERSION_FILE)                # service version number
        uuid=$(sed 's/://g' </sys/class/net/wlan0/address) # unique ID of this pi
        show_mobro "http://$1:$MOBRO_PORT?version=$version&uuid=$uuid&name=$name"

        # write found (use file as kind of global variable)
        # -> this function is started in a sub process!
        echo "1" >$MOBRO_FOUND_FLAG

        # write to file to find it faster on next boot
        echo "$1" >$HOSTS_FILE
    fi
}

service_discovery() {
    log "service_discovery" "starting service discovery"

    echo "0" >$MOBRO_FOUND_FLAG

    # check previous host if configured
    local ip key
    ip=$(sed -n 1p <$HOSTS_FILE)     # get 1st host if present (from last successful connection)
    key=$(sed -n 1p <$DISCOVERY_KEY) # 1st line contains MoBro connection key
    if ! [[ -z $ip || -z $key ]]; then
        log "service_discovery" "checking previous host"
        try_ip "$ip" "$key"
        if [[ $(cat $MOBRO_FOUND_FLAG) -eq 1 ]]; then
            # found MoBro application -> done
            return
        fi
    fi

    # search available IPs on the network
    log "service_discovery" "performing arp scan"
    case $NETWORK_MODE in
    "wifi")
        sudo arp-scan --interface=wlan0 --localnet --retry=3 --timeout=500 --backoff=2 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" 2>>$LOG_FILE 1>>"$HOSTS_FILE"
        ;;
    "eth")
        sudo arp-scan --interface=eth0 --localnet --retry=3 --timeout=500 --backoff=2 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" 2>>$LOG_FILE 1>>"$HOSTS_FILE"
        ;;
    esac

    while read -r ip; do
        try_ip "$ip" "$key"
        if [[ $(cat $MOBRO_FOUND_FLAG) -eq 1 ]]; then
            # found MoBro application -> done
            return
        fi
    done <$HOSTS_FILE

    # fallback: get current ip of pi to try all host in range
    log "service_discovery" "fallback"
    local pi_ip
    case $NETWORK_MODE in
    "wifi")
        pi_ip=$(ifconfig wlan0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' 2>>$LOG_FILE)
        ;;
    "eth")
        pi_ip=$(ifconfig eth0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' 2>>$LOG_FILE)
        ;;
    esac
    if [[ -n $pi_ip ]]; then
        local pi_ip_1 pi_ip_2 pi_ip_3 pi_ip_4
        pi_ip_1=$(echo "$pi_ip" | cut -d . -f 1)
        pi_ip_2=$(echo "$pi_ip" | cut -d . -f 2)
        pi_ip_3=$(echo "$pi_ip" | cut -d . -f 3)
        pi_ip_4=0
        log "service_discovery" "trying all IPs in range $pi_ip_1.$pi_ip_2.$pi_ip_3.X"

        local num_cores
        num_cores=$(nproc --all)
        while [[ $pi_ip_4 -lt 255 ]]; do
            for j in $(seq $((4 * num_cores))); do
                try_ip "$pi_ip_1.$pi_ip_2.$pi_ip_3.$pi_ip_4" "$key" &
                pids[$j]=$! # remember pids of started sub processes
                if [[ pi_ip_4 -ge 255 ]]; then
                    break
                fi
                pi_ip_4=$((pi_ip_4 + 1))
            done

            # wait for all started checks to finish
            for pid in ${pids[*]}; do
                wait $pid
            done
            unset pids

            # no need to continue if found
            if [[ $(cat $MOBRO_FOUND_FLAG) -eq 1 ]]; then
                return
            fi
        done
    fi

    if [[ $(cat $MOBRO_FOUND_FLAG) -ne 1 ]]; then
        # couldn't find application -> delete IPs
        log "service_discovery" "no MoBro application found"
        truncate -s 0 $HOSTS_FILE
        show_image $IMAGE_NOTFOUND
    fi
}

hotspot_check() {
    local updated ssid pw
    updated=$(sed -n 3p <$WIFI_FILE) # 3rd line contains updated timestamp
    ssid=$(sed -n 1p <$WIFI_FILE)    # 1st line contains SSID
    pw=$(sed -n 2p <$WIFI_FILE)      # 2nd line contains PW
    if [[ -n $updated ]]; then
        if [[ $updated != "$LAST_CHECKED_WIFI" ]]; then
            if ! [[ -z $ssid || -z $pw ]]; then
                # if there is new access data -> instantly try connecting
                LAST_CHECKED_WIFI=$updated
                HOTSPOT_COUNTER=0
                log "hotspot_check" "new credentials found. trying to connect to SSID $ssid"
                connect_wifi "$ssid" "$pw"
                return
            fi
        fi
    fi

    HOTSPOT_COUNTER=$((HOTSPOT_COUNTER + 1))
    if [[ $HOTSPOT_COUNTER -ge $CHECK_INTERVAL_HOTSPOT ]]; then
        log "hotspot_check" "start hotspot check"
        HOTSPOT_COUNTER=0
        if ! [[ -z $ssid || -z $pw ]]; then
            # wifi configured -> try again
            log "hotspot_check" "trying again to connect to $ssid"
            connect_wifi "$ssid" "$pw"
        fi
    fi
}

background_check() {
    local key updated
    key=$(sed -n 1p <$DISCOVERY_KEY)     # 1st line contains discovery key
    updated=$(sed -n 2p <$DISCOVERY_KEY) # 2nd line contains updated timestamp
    if [[ -n $updated && -n $key ]]; then
        if [[ $updated != "$LAST_CHECKED_KEY" ]]; then
            # there is a new disocery key -> use new key
            LAST_CHECKED_KEY=$updated
            log "background_check" "new discovery key found"
            BACKGROUND_COUNTER=0
            show_image $IMAGE_DISCOVERY 2
            service_discovery
            return
        fi
    fi

    BACKGROUND_COUNTER=$((BACKGROUND_COUNTER + 1))
    if [[ $BACKGROUND_COUNTER -ge $CHECK_INTERVAL_BACKGROUND ]]; then
        log "background_check" "starting background check"
        BACKGROUND_COUNTER=0
        if [[ $(cat $MOBRO_FOUND_FLAG) -ne 1 ]]; then
            show_image $IMAGE_DISCOVERY
        fi
        service_discovery
    fi
}

initial_wifi_check() {
    # check if wifi is configured
    # (skip if no network set - e.g. first boot)
    if [[ $(wc -l <$WIFI_FILE) -lt 4 ]]; then
        log "Startup" "no previous network configuration found"
        create_access_point
        return
    fi

    show_image $IMAGE_CONNECTWIFI
    # check if configured network is in range
    log "Startup" "scanning for wireless networks"
    search_ssids
    local wait_wifi ssid
    wait_wifi=1
    if [[ $(wc -l <$NETWORKS_FILE) -ge 1 ]]; then # check if scan returned anything first
        ssid=$(sed -n 1p <$WIFI_FILE) # ssid of configured network
        if [[ $(grep "$ssid" -c <$NETWORKS_FILE) -eq 0 ]]; then
            wait_wifi=0
        fi
    fi

    if [[ $wait_wifi -ne 1 ]]; then
        # previous wifi not reachable
        log "Startup" "configured wifi network not in range"
        show_image $IMAGE_WIFIFAILED
        create_access_point
        return
    fi

    log "Startup" "waiting for wifi connection..."
    local wifi_connected wifi_connect_count
    wifi_connected=0
    wifi_connect_count=0
    until [[ $wifi_connect_count -ge $STARTUP_WIFI_WAIT ]]; do
        if [[ $(iwgetid wlan0 --raw) ]]; then
            wifi_connected=1
            break
        fi
        sleep 5
        wifi_connect_count=$((wifi_connect_count + 5))
    done

    if [[ $wifi_connected -ne 1 ]]; then
        log "Startup" "couldn't connect to wifi"
        show_image $IMAGE_WIFIFAILED
        create_access_point
        return
    fi

    log "Startup" "connected to wifi"
    show_image $IMAGE_WIFISUCCESS 3

    # search network for application
    show_image $IMAGE_DISCOVERY 2
    service_discovery
}

# ====================================================================================================================
# Startup Sequence
# ====================================================================================================================

# copy log files to preserve the previous 10 starts

for i in {8..0}; do
    mv -f "$LOG_DIR/log_$i.txt" "$LOG_DIR/log_$((i + 1)).txt" 2>/dev/null
done
cp -f $LOG_FILE "$LOG_DIR/log_0.txt" 2>/dev/null

# clear current log
echo '' >$LOG_FILE

log "Startup" "starting service"

# env vars
export DISPLAY=:0

# reset flag
echo "0" >$MOBRO_FOUND_FLAG

# disable dnsmasq and hostapd
log "Startup" "disabling services: dnsmasq, hostapd"
{
    sudo systemctl stop
    sudo systemctl disable dnsmasq.service
    sudo systemctl stop hostapd
    sudo systemctl disable hostapd.service
} &>>$LOG_FILE

# start x
log "Startup" "starting x server"
sudo xinit \
    /bin/sh -c "exec /usr/bin/matchbox-window-manager -use_titlebar no -use_cursor no" \
    -- -nocursor \
    &>>$LOG_FILE &

# wait for x server
while ! xset q &>/dev/null; do
    log "Startup" "waiting for X.."
    sleep 5
done
sleep_pi 2 5

# show background
show_image $IMAGE_MOBRO 7

# start webserver
log "Startup" "starting lighttpd"
sudo systemctl start lighttpd &>>$LOG_FILE

# disabling screen blanking
log "Startup" "disable blank screen"
{
    sudo xset s off
    sudo xset -dpms
    sudo xset s noblank
} &>>$LOG_FILE

# determine and set network mode
if [[ $(grep up /sys/class/net/*/operstate | grep eth0 -c) -gt 0 ]]; then
    log "Startup" "network mode set to ETHERNET"
    NETWORK_MODE='eth'
else
    log "Startup" "network mode set to WIFI"
    NETWORK_MODE='wifi'
fi

# check for wifi interface
if [[ $(ifconfig -a | grep wlan -c) -lt 1 ]]; then
    log "Startup" "no wifi interface detected, aborting"
    show_image $IMAGE_NOWIFIINTERFACE
    while true; do
        sleep 60
    done
fi

# we need to set the global variables for last checks
LAST_CHECKED_WIFI=$(sed -n 4p <$WIFI_FILE)    # 4th line contains updated timestamp
LAST_CHECKED_KEY=$(sed -n 2p <$DISCOVERY_KEY) # 2nd line contains updated timestamp

case $NETWORK_MODE in
"wifi")
    # try to connect to wifi (if previously configured)
    # and try to connect to mobro
    initial_wifi_check
    ;;
"eth")
    show_image $IMAGE_ETHSUCCESS 3
    # search network for application
    show_image $IMAGE_DISCOVERY 2
    service_discovery
    ;;
esac

# ====================================================================================================================
# Main Loop
# ====================================================================================================================

log "Main" "Entering main loop"
while true; do
    if [[ $((LOOP_COUNTER % 10)) -eq 0 ]]; then
        log "Main" "loop $LOOP_COUNTER"
    fi

    case $NETWORK_MODE in
    "wifi")
        if [[ $(create_ap --list-running | grep wlan0 -c) -eq 0 ]]; then
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
        ;;
    "eth")
        background_check
        ;;
    esac

    sleep $LOOP_INTERVAL
    LOOP_COUNTER=$((LOOP_COUNTER + 1))
done

log "Main" "unexpected shutdown"
