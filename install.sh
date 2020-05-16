#!/bin/bash

# ==========================================================
# Modbros Monitoring Service - Raspberry Pi
#
# installation script
# (intended for and tested only on clean Raspbian Buster lite)
#
# Created with <3 in Austria by: (c) ModBros 2020
# Contact: mod-bros.com
# ==========================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges"
    echo "Please run again as 'sudo ./install.sh'"
    exit 1
fi

if [[ $(curl -o /dev/null --silent --write-out '%{http_code}' http://www.google.at) -ne 200 ]]; then
    echo "This installation requires internet access"
    echo "Please make sure the Pi is connected to a network"
    exit 1
fi

# ==========================================================
# Add user and setting permissions
# ==========================================================

echo -n "Setting necessary permissions for modbros user..."

usermod -aG sudo modbros >/dev/null
userdel -r -f pi >/dev/null

chmod 440 ./config/010_modbros-nopasswd
cp -f ./config/010_modbros-nopasswd /etc/sudoers.d

echo " done"

# ==========================================================
# Set file permissions
# ==========================================================

echo -n "Setting script and file permissions..."

chmod 755 ./scripts/*.sh
chmod 755 ./service/modbros.sh

chmod 644 ./service/modbros.service
chmod 666 ./data/*
chmod 666 ./log/*
chmod 666 ./config/*
chmod 444 ./resources/*

echo " done"

# ==========================================================
# update Pi
# ==========================================================

echo -n "Updating Raspberry..."
apt-get update >/dev/null
apt-get upgrade -y >/dev/null
echo " done"

# ==========================================================
# install dependencies
# ==========================================================

echo "Installing dependencies"
apt-get update >/dev/null
while read dep; do
    echo -n "Installing $dep..."
    apt-get -y install "$dep" >/dev/null
    echo " done"
done <"./dependencies.txt"

# ==========================================================
# Stop and disable access point services + bluetooth
# ==========================================================

systemctl stop dnsmasq >/dev/null
systemctl stop hostapd >/dev/null

systemctl disable dnsmasq.service >/dev/null
systemctl disable hostapd.service >/dev/null

systemctl disable hciuart >/dev/null

# ==========================================================
# configuring web server and resources
# ==========================================================

echo -n "Configuring web server and resources..."

rm -rf /var/www/*

chmod +rx ./web/modbros/favicon.ico
ln -s /home/modbros/ModbrosMonitoring/web /var/www/html
ln -s /home/modbros/ModbrosMonitoring/data /home/modbros/ModbrosMonitoring/web/data
ln -s /home/modbros/ModbrosMonitoring/log /home/modbros/ModbrosMonitoring/web/log

sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g" /etc/php/7.3/fpm/php.ini
cat ./config/15-fastcgi-php.conf >/etc/lighttpd/conf-available/15-fastcgi-php.conf

lighttpd-enable-mod fastcgi >/dev/null
lighttpd-enable-mod fastcgi-php >/dev/null

echo " done"

echo -n "Restarting web server..."
service lighttpd force-reload >/dev/null
service lighttpd restart >/dev/null
systemctl enable lighttpd.service >/dev/null
echo " done"

echo -n "Setting permissions for wwwdata user..."
cp -f ./config/010_wwwdata-scripts /etc/sudoers.d
chmod 440 /etc/sudoers.d/010_wwwdata-scripts
echo " done"

# ==========================================================
# Applying configuration
# ==========================================================

echo -n "Applying configurations..."

cat ./config/config.txt >/boot/config.txt
sed ' 1 s/.*/& consoleblank=0/' /boot/cmdline.txt

cat ./config/hostname >/etc/hostname
cat ./config/hosts >/etc/hosts

echo " done"

# ==========================================================
# swap + eeprom update
# =========================================================x=

echo -n "Disabling automatic eeprom update..."
# Prevent the automatic eeprom update service from running
systemctl mask rpi-eeprom-update >/dev/null
echo " done"

echo -n "Turning off swap..."
# turn off swap
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt purge dphys-swapfile
echo " done"

# ==========================================================
# Display drivers
# ==========================================================

echo -n "Pulling display drivers..."

git clone https://github.com/goodtft/LCD-show.git /home/modbros/DisplayDrivers/GoodTFT
git clone https://github.com/waveshare/LCD-show.git /home/modbros/DisplayDrivers/Waveshare

echo " done"

echo -n "Setting permission for display drivers..."
chmod +x /home/modbros/DisplayDrivers/GoodTFT/*show
chmod +x /home/modbros/DisplayDrivers/Waveshare/*show
echo " done"

# ==========================================================
# createAp
# ==========================================================

echo -n "Installing access point script..."

rm -rf create_ap
git clone https://github.com/oblique/create_ap
chmod -R 755 create_ap
cd create_ap || exit
make install
cd ..
rm -rf create_ap

echo " done"

# ==========================================================
# Cleanup
# ==========================================================

echo -n "Removing no longer relevant packages..."
apt-get autoremove --purge -y >/dev/null
apt-get autoclean -y >/dev/null
apt-get clean -y >/dev/null
echo " done"

# ==========================================================
# Service
# ==========================================================

echo -n "Installing the ModBros service..."

ln -s /home/modbros/ModbrosMonitoring/service/modbros.service /lib/systemd/system/modbros.service
systemctl daemon-reload
systemctl enable modbros.service
systemctl stop modbros.service

echo " done"

# ==========================================================
# Reboot
# ==========================================================

echo "Installation completed"
echo "Rebooting..."

sleep 5

reboot

exit 0

# TODO still missing in script:
# tmpfs entry to /etc/fstab
# set php log dir to our log dir
