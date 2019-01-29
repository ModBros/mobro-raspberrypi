#!/bin/bash

# TODO

systemctl stop hostapd
systemctl stop dnsmasq

cp -f /etc/dhcpcd.conf.orig /etc/dhcpcd.conf
service dhcpcd restart

rm -f /etc/wpa_supplicant/wpa_supplicant.conf
cp -f /etc/wpa_supplicant/wpa_supplicant.conf.orig /etc/wpa_supplicant/wpa_supplicant.conf

wpa_cli -i wlan0 reconfigure

# TODO