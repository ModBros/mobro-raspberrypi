#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script requires root privileges"
  exit 1
fi

if grep -q "boot=overlay" /proc/cmdline; then
  echo "OverlayFS is still enabled!"
  exit 1
fi

# remove development files
rm -f /home/modbros/mobro-raspberrypi/dependencies.txt
rm -f /home/modbros/mobro-raspberrypi/mobro-raspberrypi.iml
rm -rf /home/modbros/mobro-raspberrypi/.idea

# remove documentation from already installed packages
rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

# remove log files
rm -f /var/log/{auth,boot,bootstrap,daemon,kern}.log
rm -f /var/log/{debug,dmesg,messages,syslog}

rm -f /home/modbros/mobro-raspberrypi/log/log_?.txt

# clean apt cache
apt-get clean

# reset wpa config
cp -f /home/modbros/mobro-raspberrypi/config/wpa_supplicant_clean.conf /etc/wpa_supplicant/wpa_supplicant.conf

# reset config file
cat /home/modbros/mobro-raspberrypi/config/mobro_config_default >/home/modbros/mobro-raspberrypi/config/mobro_config

# delete cache + bash history
rm -rf /home/modbros/.cache/*
: >/home/modbros/.bash_history

# reset driver
cat /home/modbros/mobro-raspberrypi/config/config.txt >/boot/config.txt
cat /home/modbros/mobro-raspberrypi/config/99-fbturbo.conf >/usr/share/X11/xorg.conf.d/99-fbturbo.conf
sudo rm -rf /etc/X11/xorg.conf.d/*

# overwrite free space of partitions
#sfill -f -z -l -l -v /
#sfill -f -z -l -l -v /boot
#sfill -f -z -l -l -v /home
