#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    exit 1
fi

# remove development files
rm -f /home/modbros/mobro-raspberrypi/dependencies.txt
rm -f /home/modbros/mobro-raspberrypi/mobro-raspberrypi.iml
rm -f /home/modbros/mobro-raspberrypi/install.sh
rm -rf /home/modbros/mobro-raspberrypi/.idea

# remove documentation from already installed packages
rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

# remove log files
rm -f /var/log/{auth,boot,bootstrap,daemon,kern}.log
rm -f /var/log/{debug,dmesg,messages,syslog}

rm -f /home/modbros/mobro-raspberrypi/log/log_?.txt
: >/home/modbros/mobro-raspberrypi/log/log.txt

# clean apt cache
apt-get clean

# reset wpa config
cp -f /home/modbros/mobro-raspberrypi/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf

# reset data files
: >/home/modbros/mobro-raspberrypi/data/hosts
: >/home/modbros/mobro-raspberrypi/data/wifi
: >/home/modbros/mobro-raspberrypi/data/ssids
: >/home/modbros/mobro-raspberrypi/data/display

echo "0" >/home/modbros/mobro-raspberrypi/data/mobro_found

echo "mode=auto" >/home/modbros/mobro-raspberrypi/data/discovery
echo "key=mobro" >>/home/modbros/mobro-raspberrypi/data/discovery
echo "ip=" >>/home/modbros/mobro-raspberrypi/data/discovery

# delete cache + bash history
rm -rf /home/modbros/.cache/*
: >/home/modbros/.bash_history

# overwrite free space of partition
#sfill -f -z -l -l -v /
