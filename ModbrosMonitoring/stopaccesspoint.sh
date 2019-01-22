#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
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
service networking restart
