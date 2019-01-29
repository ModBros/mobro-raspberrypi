#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments supplied"
    exit 1
fi

if [[ ! -f /etc/wpa_supplicant/wpa_supplicant.conf.orig ]]; then
    echo "Original copy of 'wpa_supplicant.conf' missing!"
    echo "Did you run the install script first?"
    exit 1
fi


# =============================
# Stop access point services
# =============================

systemctl stop dnsmasq
systemctl stop hostapd


# =============================
# disable static ip
# =============================

cp -f /etc/dhcpcd.conf.orig /etc/dhcpcd.conf
service dhcpcd restart


# =============================
# configure network
# =============================

#cp -f /etc/wpa_supplicant/wpa_supplicant.conf.orig /etc/wpa_supplicant/wpa_supplicant.conf.tmp
cat ../Config/wpa_supplicant.conf > /etc/wpa_supplicant/wpa_supplicant.conf.tmp

sed -i -e "s/SSID_PLACEHOLDER/$1/g" /etc/wpa_supplicant/wpa_supplicant.conf.tmp
sed -i -e "s/PW_PLACEHOLDER/$2/g" /etc/wpa_supplicant/wpa_supplicant.conf.tmp

mv -f /etc/wpa_supplicant/wpa_supplicant.conf.tmp /etc/wpa_supplicant/wpa_supplicant.conf


# =============================
# restart networking
# =============================

#ifconfig wlan0 up
#wpa_cli -i wlan0 reconfigure
service networking restart
