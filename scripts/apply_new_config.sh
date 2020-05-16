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
DATA_DIR='/home/modbros/mobro-raspberrypi/data'
CONF_DIR='/home/modbros/mobro-raspberrypi/config'

# Files
WPA_CONFIG_EMPTY="$CONF_DIR/wpa_supplicant_empty.conf"
WPA_CONFIG_CLEAN="$CONF_DIR/wpa_supplicant_clean.conf"
WPA_CONFIG_TEMP="$CONF_DIR/wpa_supplicant_temp.conf"

DRIVER_FILE="$DATA_DIR/driver"
WIFI_FILE="$DATA_DIR/wifi"
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

wifi_config() {
    log "configuration" "starting network configuration"
    local mode, ssid, pw, country, wpa, hidden, updated
    mode=$(prop 'mode' $WIFI_FILE)

    if [[ $mode == "eth" ]]; then
        # connected by ethernet => set standard wpa config and we're done
        log "configuration" "network mode: Ethernet - resetting wpa_supplicant"
        sudo cp -f $WPA_CONFIG_CLEAN /etc/wpa_supplicant/wpa_supplicant.conf
        return
    fi

    log "configuration" "network mode: Wifi - creating new wpa_supplicant"
    ssid=$(prop 'ssid' $WIFI_FILE)
    pw=$(prop 'pw' $WIFI_FILE)
    country=$(prop 'country' $WIFI_FILE)
    wpa=$(prop 'wpa' $WIFI_FILE)
    hidden=$(prop 'hidden' $WIFI_FILE)

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
}

driver() {
    local driver
    driver=$(sed -n 1p <$DRIVER_FILE)

    if [[ -n "$driver" ]]; then
        : >$DRIVER_FILE
        cd "$(dirname "$driver")" || exit
        log "configuration" "installing new display driver: $driver"
        sudo /bin/bash "$driver" >>$LOG_FILE
    else
        log "configuration" "skipping display driver installation"
    fi
}

# ====================================================================================================================
# Main Script
# ====================================================================================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    exit 1
fi

log "configuration" "starting to apply new configuration"

# set new wifi configuration
wifi_config

# install driver is it was selected
driver

# reboot the Pi
log "configuration" "done - rebooting"
sudo shutdown -r now
