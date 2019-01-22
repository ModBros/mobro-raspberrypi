#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

if [[ ! -f /etc/wpa_supplicant/wpa_supplicant.conf.orig ]]; then
    echo "Original copy of 'wpa_supplicant.conf' missing!"
    echo "Did you run the install script first?"
    exit 1
fi


# =============================
# Stop services
# =============================

systemctl stop dnsmasq
systemctl stop hostapd

# =============================
# Scan for available networks
# =============================

iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/' > /var/www/html/modbros/networks


# =============================
# Reset wpa_supplicant
# =============================

rm -f /etc/wpa_supplicant/wpa_supplicant.conf
cp -f /etc/wpa_supplicant/wpa_supplicant.conf.orig /etc/wpa_supplicant/wpa_supplicant.conf

# wpa_cli -i wlan0 reconfigure

# =============================
# disable static ip
# =============================

cp -f /etc/dhcpcd.conf.orig /etc/dhcpcd.conf
service dhcpcd restart


# =============================
# restart networking
# =============================


service networking restart
