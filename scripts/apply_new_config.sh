#!/bin/bash

# ====================================================================================================================
# Modbros Monitoring Service (MoBro) - Raspberry Pi image
# Copyright (C) 2021 ModBros
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
readonly CONF_DIR='/home/modbros/mobro-raspberrypi/config'
readonly SCRIPT_DIR='/home/modbros/mobro-raspberrypi/scripts'

# Scripts
readonly FS_MOUNT_SCRIPT="$SCRIPT_DIR/fsmount.sh"

# Files
readonly WPA_CONFIG_EMPTY="$CONF_DIR/wpa_supplicant_empty.conf"
readonly WPA_CONFIG_CLEAN="$CONF_DIR/wpa_supplicant_clean.conf"
readonly WPA_CONFIG_TEMP="$CONF_DIR/wpa_supplicant_temp.conf"
readonly FBTURBO_CONFIG="$CONF_DIR/99-fbturbo.conf"
readonly MOBRO_CONFIG="$CONF_DIR/mobro_config"
readonly MOBRO_CONFIG_TXT="$CONF_DIR/mobro_configtxt"
readonly MOBRO_CONFIG_TXT_DEFAULT="$CONF_DIR/config.txt"
readonly MOBRO_CMDLINE_DEFAULT="$CONF_DIR/cmdline.txt"
readonly GETHER_CONFIG="$CONF_DIR/g_ether.conf"
readonly USB0_CONFIG="$CONF_DIR/usb0"

readonly CONFIG_TXT="/boot/config.txt"
readonly CMDLINE_TXT="/boot/cmdline.txt"
readonly MOBRO_CONFIG_BOOT="/mobro/mobro_config"
readonly MOBRO_CONFIG_TXT_BOOT="/mobro/mobro_configtxt"

readonly LOG_FILE="/tmp/mobro_log"

# ====================================================================================================================
# Helper Functions
# ====================================================================================================================

log() {
    local temp date throttle
    temp=$(sudo vcgencmd measure_temp)
    date=$(date "+%d.%m.%y %T")
    throttle=$(sudo vcgencmd get_throttled)
    echo "$date [${temp:5:-4}][${throttle:10}][$1] $2" >>$LOG_FILE
}

prop() {
    grep "$1=" "$2" | cut -d '=' -f2
}

add_wpa() {
    echo "$1" >>"$WPA_CONFIG_TEMP"
}

add_wpa_setting() {
    if [[ -n "$2" ]]; then
        echo "$1=$2" >>"$WPA_CONFIG_TEMP"
    fi
}

get_overlay_now() {
    grep -q "boot=overlay" /proc/cmdline
}

get_bootro_now() {
    findmnt /boot | grep -q " ro,"
}

is_pione() {
    if grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo; then
        return 0
    elif grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo ; then
        return 0
    fi
    return 1
}

is_pitwo() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

is_pizero() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

is_pifour() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]3[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

set_config_var() {
  log "configuration" "setting $1 to $2"
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end
if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

clear_config_var() {
  log "configuration" "clearing '$1'"
  lua - "$1" "$2" <<EOF > "$2.bak"
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  if line:match("^%s*"..key.."=.*$") then
    line="#"..line
  end
  print(line)
end
EOF
mv "$2.bak" "$2"
}

set_overclock() {
    set_config_var arm_freq "$1" "$CONFIG_TXT"
    set_config_var core_freq "$2" "$CONFIG_TXT"
    set_config_var sdram_freq "$3" "$CONFIG_TXT"
    set_config_var over_voltage "$4" "$CONFIG_TXT"
}

clear_overclock() {
    clear_config_var arm_freq "$CONFIG_TXT"
    clear_config_var core_freq "$CONFIG_TXT"
    clear_config_var sdram_freq "$CONFIG_TXT"
    clear_config_var over_voltage "$CONFIG_TXT"
}

add_cmdline() {
    if ! grep -q "$1" "$CMDLINE_TXT" ; then
        sed -i "$CMDLINE_TXT" -e "s/^/$1 /"
    fi
}

# ====================================================================================================================
# Configuration Functions
# ====================================================================================================================

configtxt_manual() {
    log "configuration" "starting manual config.txt configuration"
    cat -n "$1" &>> $LOG_FILE
    if [[ ! -f "$1" ]]; then
        log "configuration" "given manual config.txt file '$1' does not exist - skipping"
        return
    fi
    log "configuration" "adding manual entries to config.txt:"
    cat -n "$1" &>>$LOG_FILE
    cat "$1" >>$CONFIG_TXT
}

overclock() {
    log "configuration" "starting overclock"
    local overclock consent
    consent=$(prop 'advanced_overclock_consent' "$1");
    overclock=$(prop 'advanced_overclock_mode' "$1");
    if [[ "$consent" != "1" ]]; then
        log "configuration" "no consent to overclocking - skipping"
        return
    fi
    case "$overclock" in
        modest)
            if is_pione; then
                log "configuration" "applying 'Modest' overclock on Pi 1"
                set_overclock 800 250 400 0
            fi
            ;;
        medium)
            if is_pione; then
                log "configuration" "applying 'Medium' overclock on Pi 1"
                set_overclock 900 250 450 2
            fi
            ;;
        high)
            if is_pizero; then
                log "configuration" "applying 'High' overclock on Pi Zero"
                set_overclock 1050 450 450 6
            elif is_pione; then
                log "configuration" "applying 'High' overclock on Pi 1"
                set_overclock 950 250 450 6
            elif is_pitwo; then
                log "configuration" "applying 'High' overclock on Pi 2"
                set_overclock 1000 500 500 2
            fi
            ;;
        turbo)
            if is_pizero; then
                log "configuration" "applying 'Turbo' overclock on Pi Zero"
                set_overclock 1100 500 500 6
            elif is_pione; then
                log "configuration" "applying 'Turbo' overclock on Pi 1"
                set_overclock 1000 500 600 6
            fi
            ;;
        *)
            log "configuration" "no overclock selected - clearing"
            clear_overclock
            ;;
    esac
}

timezone_config() {
    log "configuration" "starting timezone configuration"
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

    usb)
        # connected by usb
        log "configuration" "network mode: USB Ethernet - resetting wpa_supplicant"
        sudo cp -f $WPA_CONFIG_CLEAN /etc/wpa_supplicant/wpa_supplicant.conf
        echo -e "\ndtoverlay=dwc2" >>"$CONFIG_TXT"
        add_cmdline "modules-load=dwc2,g_ether"
        sudo cp -f $USB0_CONFIG /etc/network/interfaces.d/usb0
        sudo cp -f $GETHER_CONFIG /etc/modprobe.d/g_ether.conf
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

display_config() {
    log "configuration" "starting display driver configuration"
    local driver rotation rotation_val
    driver=$(prop 'display_driver' "$1")
    rotation=$(prop 'display_rotation' "$1")
    if [[ -z "$rotation" ]]; then
        rotation=0
    fi
    rotation_val=$((rotation / 90))
    case "$driver" in
    "")
        log "configuration" "no driver set"
        ;;
    default)
        log "configuration" "display driver: default"
        log "configuration" "display rotation: $rotation"
        cat "$FBTURBO_CONFIG" >/usr/share/X11/xorg.conf.d/99-fbturbo.conf
        sudo rm -f /etc/X11/xorg.conf.d/*
        if [[ $rotation_val == 0 ]]; then
            clear_config_var display_rotate "$CONFIG_TXT"
        else
            set_config_var display_rotate "$rotation_val" "$CONFIG_TXT"
        fi
        ;;
    pi7)
        log "configuration" "display driver: pi 7"
        log "configuration" "display rotation: $rotation"
        if [[ $rotation_val == 0 || $rotation_val == 2 ]]; then
            set_config_var lcd_rotate "$rotation_val" "$CONFIG_TXT"
        else
            set_config_var display_rotate "$rotation_val" "$CONFIG_TXT"
        fi
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

persistent_logging() {
    if [[ $(prop 'advanced_fs_persist_log' "$1") == "1" ]]; then
        log "configuration" "enabling shutdownlog service"
        sudo cp -f /home/modbros/mobro-raspberrypi/service/shutdownlog.service /lib/systemd/system/shutdownlog.service
        sudo systemctl daemon-reload
        sudo systemctl enable shutdownlog.service
    else
        log "configuration" "disabling shutdownlog service"
        sudo systemctl disable shutdownlog.service
    fi
}

nosplash_config() {
    set_config_var start_x 0 "$CONFIG_TXT"
    set_config_var disable_splash 1 "$CONFIG_TXT"
}

# ====================================================================================================================
# Main Script
# ====================================================================================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    log "configuration" "failed to apply new configuration: privileges"
    exit 1
fi

if [[ "$#" -lt 1 ]]; then
    echo "Illegal number of parameters"
    log "configuration" "failed to apply new configuration: no config file given"
    exit 1
fi

if [[ ! -f "$1" ]]; then
    echo "config file '$1' does not exist"
    log "configuration" "failed to apply new configuration: invalid config file given"
    exit 1
fi

if [[ ! -s "$1" ]]; then
    echo "config file '$1' is empty"
    log "configuration" "failed to apply new configuration: config file was empty"
    exit 1
fi

if [[ -n "$2" ]]; then
    if [[ ! -f "$2" ]]; then
        echo "config file '$2' does not exist"
        log "configuration" "failed to apply new configuration: invalid config.txt file given"
        exit 1
    fi
fi

# if overlayFS is currently active: save configuration and apply on reboot
if get_overlay_now; then
    log "configuration" "disabling OverlayFS"
    sudo /bin/bash "$FS_MOUNT_SCRIPT" --rw root &>>$LOG_FILE

    log "configuration" "persisting configuration for next boot"
    cp -f "$1" "$MOBRO_CONFIG_BOOT"
    if [[ -n "$2" ]]; then
        cp -f "$2" "$MOBRO_CONFIG_TXT_BOOT"
    fi

    log "configuration" "rebooting"
    sudo shutdown -r now
    exit 0;
fi

# mount the boot partition as writable if it isn't already
if get_bootro_now; then
    log "configuration" "remounting /boot as writable"
    sudo /bin/bash "$FS_MOUNT_SCRIPT" --rw boot &>>$LOG_FILE
fi

log "configuration" "starting to apply new configuration:"
# do not write the wifi password to log
cat -n "$1" | sed '/network_pw/d' &>>$LOG_FILE

log "configuration" "persisting new configuration"
cp -f "$1" "$MOBRO_CONFIG"
if [[ -n "$2" ]]; then
    cp -f "$2" "$MOBRO_CONFIG_TXT"
fi

log "configuration" "resetting config.txt + cmdline.txt"
cat "$MOBRO_CONFIG_TXT_DEFAULT" >"$CONFIG_TXT"
cat "$MOBRO_CMDLINE_DEFAULT" >"$CMDLINE_TXT"

# configure timezone
timezone_config "$1"

# handle display drivers
display_config "$1"

# set some of the config,txt values again that might
# have been removed by the display driver
nosplash_config

# set new network configuration
network_config "$1"

# handle overclock
overclock "$1"

# enable/disable persistent logging
persistent_logging "$1"

# handle manual config txt
if [[ -n "$2" ]]; then
    configtxt_manual "$2"
fi

if [ "$1" = "$MOBRO_CONFIG_BOOT" ]; then
    log "configuration" "just applied reboot configuration - removing"
    rm -f "$MOBRO_CONFIG_BOOT"
    rm -f "$MOBRO_CONFIG_TXT_BOOT"
fi

# mount the boot partition as read-only again
if get_bootro_now; then
    log "configuration" "remounting /boot as writable"
    sudo /bin/bash "$FS_MOUNT_SCRIPT" --ro boot &>>$LOG_FILE
fi

# enable OverlayFS again if not disabled
if [[ $(prop 'advanced_fs_dis_overlayfs' "$1") != "1" ]]; then
    log "configuration" "enabling OverlayFS"
    sudo dhcpcd --release
    sudo systemctl stop dhcpcd
    sudo rm -rf /var/lib/dhcpcd5/*
    sudo /bin/bash "$FS_MOUNT_SCRIPT" --ro root &>>$LOG_FILE
fi

log "configuration" "done - rebooting"
sudo shutdown -r now
