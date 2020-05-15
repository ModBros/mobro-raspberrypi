#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    exit 1
fi

# remove development files
rm -f /home/modbros/ModbrosMonitoring/dependencies.txt
rm -f /home/modbros/ModbrosMonitoring/ModbrosMonitoring.iml
rm -f /home/modbros/ModbrosMonitoring/install.sh
rm -rf /home/modbros/ModbrosMonitoring/.idea

# remove documentation from already installed packages
rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

# remove log files
rm -f /var/log/{auth,boot,bootstrap,daemon,kern}.log
rm -f /var/log/{debug,dmesg,messages,syslog}

rm -f /home/modbros/ModbrosMonitoring/log/log_?.txt
: >/home/modbros/ModbrosMonitoring/log/log.txt

# clean apt cache
apt-get clean

# reset wpa config
cp -f /home/modbros/ModbrosMonitoring/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf

# reset data files
: >/home/modbros/ModbrosMonitoring/data/hosts
: >/home/modbros/ModbrosMonitoring/data/wifi
: >/home/modbros/ModbrosMonitoring/data/ssids
: >/home/modbros/ModbrosMonitoring/data/driver

echo "0" >/home/modbros/ModbrosMonitoring/data/mobro_found

echo "mode=auto" >/home/modbros/ModbrosMonitoring/data/discovery
echo "key=mobro" >>/home/modbros/ModbrosMonitoring/data/discovery
echo "ip=" >>/home/modbros/ModbrosMonitoring/data/discovery

# delete cache + bash history
rm -rf /home/modbros/.cache/*
: >/home/modbros/.bash_history

# overwrite free space of partition
#sfill -f -z -l -l -v /
