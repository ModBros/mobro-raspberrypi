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

if [[ ! -f /etc/dhcpcd.conf.orig ]]; then
    echo "Original copy of 'dhcpcd.conf' missing!"
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
# Configure static ip
# =============================

cp -f /etc/dhcpcd.conf.orig /etc/dhcpcd.conf.tmp
cat ../Config/dhcpcd.conf >> /etc/dhcpcd.conf.tmp

mv -f /etc/dhcpcd.conf.tmp /etc/dhcpcd.conf

service dhcpcd restart


# =============================
# Start access point services
# =============================

systemctl start hostapd
systemctl start dnsmasq

service networking restart


# =============================
# Add routing and masquerade
# =============================

#sed -i '/net.ipv4.ip_forward=1/s/^#//g' file
#
#iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
#
#sh -c "iptables-save > /etc/iptables.ipv4.nat"



#sed -i '/PATTERN/s/^/#/g' file    (to comment out)
#sed -i '/PATTERN/s/^#//g' file    (to uncomment)