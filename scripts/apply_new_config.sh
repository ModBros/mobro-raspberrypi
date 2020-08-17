#!/bin/bash

# ====================================================================================================================
# Modbros Monitoring Service (MoBro) - Raspberry Pi image
# Copyright (C) 2020 ModBros
# Contact: mod-bros.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ====================================================================================================================

# Directories
LOG_DIR='/home/modbros/mobro-raspberrypi/log'
CONF_DIR='/home/modbros/mobro-raspberrypi/config'

# Files
WPA_CONFIG_EMPTY="$CONF_DIR/wpa_supplicant_empty.conf"
WPA_CONFIG_CLEAN="$CONF_DIR/wpa_supplicant_clean.conf"
WPA_CONFIG_TEMP="$CONF_DIR/wpa_supplicant_temp.conf"
BOOT_CONFIG="$CONF_DIR/config.txt"
FBTURBO_CONFIG="$CONF_DIR/99-fbturbo.conf"

LOG_FILE="$LOG_DIR/log.txt"

# ====================================================================================================================
# Helper Functions
# ====================================================================================================================

log() {
    local temp date
    temp=$(sudo vcgencmd measure_temp)
    date=$(date "+%d.%m.%y %T")
    echo "$date | ${temp:5} : [$1] $2" >>$LOG_FILE
}

prop() {
    grep "$1" "$2" | cut -d '=' -f2
}

add_wpa() {
    echo "$1" >>"$WPA_CONFIG_TEMP"
}

add_wpa_setting() {
    if [[ -n "$2" ]]; then
        echo "$1=$2" >>"$WPA_CONFIG_TEMP"
    fi
}

# ====================================================================================================================
# Configuration Functions
# ====================================================================================================================

timezone_config() {
    local timezone
    timezone=$(prop 'localization_timezone' "$1")
    if [[ -z "$timezone" ]]; then
        log "configuration" "no timezone set - keeping current configuration"
        return
    fi

    log "configuration" "setting timezone: $timezone"
    sudo timedatectl set-timezone "$timezone"
}

network_config() {
    log "configuration" "starting network configuration"
    local mode
    mode=$(prop 'network_mode' "$1")

    case $mode in
    "")
        log "configuration" "no network mode set - keeping current configuration"
        ;;
    eth)
        # connected by ethernet => set standard wpa config and we're done
        log "configuration" "network mode: Ethernet - resetting wpa_supplicant"
        sudo cp -f $WPA_CONFIG_CLEAN /etc/wpa_supplicant/wpa_supplicant.conf
        ;;

    wifi)
        log "configuration" "network mode: Wifi - creating new wpa_supplicant"
        local ssid pw country wpa hidden
        ssid=$(prop 'network_ssid' "$1")
        pw=$(prop 'network_pw' "$1")
        country=$(prop 'localization_country' "$1")
        wpa=$(prop 'network_wpa' "$1")
        hidden=$(prop 'network_hidden' "$1")

        # start a new config file
        cp -f $WPA_CONFIG_EMPTY $WPA_CONFIG_TEMP
        # set the selected wifi country
        log "configuration" "setting wifi country to: $country"
        add_wpa_setting 'country' "$country"

        # add a new network
        add_wpa "network={"

        # set ssid
        log "configuration" "setting SSID to: $ssid"
        add_wpa_setting 'ssid' "\"$ssid\""

        # set scan_ssid if we're using a hidden network
        log "configuration" "setting hidden SSID to: $hidden"
        if [[ $hidden == "1" ]]; then
            add_wpa_setting 'scan_ssid' "$hidden"
        fi

        # set password
        add_wpa_setting 'psk' "\"$pw\""

        # wpa version and encryption config
        log "configuration" "setting WPA mode to: $wpa"
        case $wpa in
        2a)
            add_wpa_setting "key_mgmt" "WPA-PSK"
            add_wpa_setting "proto" "RSN"
            add_wpa_setting "pairwise" "CCMP"
            add_wpa_setting "auth_alg" "OPEN"
            ;;
        2t)
            add_wpa_setting "key_mgmt" "WPA-PSK"
            add_wpa_setting "proto" "WPA"
            add_wpa_setting "pairwise" "TKIP"
            add_wpa_setting "auth_alg" "OPEN"
            ;;
        1t)
            add_wpa_setting "key_mgmt" "WPA-PSK"
            add_wpa_setting "proto" "WPA"
            add_wpa_setting "pairwise" "TKIP"
            add_wpa_setting "auth_alg" "OPEN"
            ;;
        n)
            add_wpa_setting "key_mgmt" "NONE"
            ;;
        *)
            # default settings (automatic) => no need to add anything to config
            ;;
        esac

        # close network section
        add_wpa "}"

        # set the new config
        sudo mv -f $WPA_CONFIG_TEMP /etc/wpa_supplicant/wpa_supplicant.conf
        ;;

    *)
        log "configuration" "invalid network mode set - keeping current configuration"
        ;;
    esac
}

display() {
    local driver rotation
    driver=$(prop 'display_driver' "$1")
    rotation=$(prop 'display_rotation' "$1")
    if [[ -z "$rotation" ]]; then
        rotation=0
    fi

    case "$driver" in
    "")
        log "configuration" "no driver set - keeping current configuration"
        ;;
    hdmi)
        log "configuration" "display driver: HDMI"
        cat "$BOOT_CONFIG" >/boot/config.txt
        log "configuration" "display rotation: $rotation"
        echo -e "\ndisplay_rotate=$((rotation / 90))" >>/boot/config.txt
        cat "$FBTURBO_CONFIG" >/usr/share/X11/xorg.conf.d/99-fbturbo.conf
        sudo rm -f /etc/X11/xorg.conf.d/*
        ;;
    manual)
        log "configuration" "manual display driver installation (skipping)"
        ;;
    *)
        if [[ ! -f "$driver" ]]; then
            log "configuration" "configured driver file not found: $driver"
            return
        fi
        cd "$(dirname "$driver")" || exit
        log "configuration" "installing new display driver: $driver"
        log "configuration" "display rotation: $rotation"
        sudo /bin/bash "$driver" "$rotation" >>$LOG_FILE
        ;;
    esac
}

# ====================================================================================================================
# Main Script
# ====================================================================================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    log "configuration" "failed to apply new configuration: privileges"
    exit 1
fi

if [[ "$#" -ne 1 ]]; then
    echo "Illegal number of parameters"
    log "configuration" "failed to apply new configuration: no config file given"
    exit 1
fi

if [[ ! -f "$1" ]]; then
    echo "config file '$1' does not exist"
    log "configuration" "failed to apply new configuration: no config file given"
    exit 1
fi

if [[ $(wc -l <$1) -lt 1 ]]; then
    echo "config file '$1' is empty"
    log "configuration" "failed to apply new configuration: config file was empty"
    exit 1
fi

log "configuration" "starting to apply new configuration:"
cat "$1" &>>$LOG_FILE

# configure timezone
timezone_config "$1"

# set new network configuration
network_config "$1"

# handle display drivers
display "$1"

# reboot the Pi
log "configuration" "done - rebooting"
sudo shutdown -r now
