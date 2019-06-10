#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

# remove documentation from already installed packages
find /usr/share/doc -depth -type f ! -name copyright | xargs rm || true
find /usr/share/doc -empty | xargs rmdir || true
rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

# remove log files
rm -f /var/log/{auth,boot,bootstrap,daemon,kern}.log
rm -f /var/log/{debug,dmesg,messages,syslog}

rm -f /home/modbros/ModbrosMonitoring/log/log_?.txt
: > /home/modbros/ModbrosMonitoring/log/log.txt

# clean apt cache
apt-get clean

# reset wpa config
cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf

# reset data files
: > /home/modbros/ModbrosMonitoring/data/hosts.txt
: > /home/modbros/ModbrosMonitoring/data/wifi.txt
echo -n "0" > /home/modbros/ModbrosMonitoring/data/mobro_found.txt
