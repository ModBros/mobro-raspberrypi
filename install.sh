#!/bin/bash

# ==========================================================================
# Modbros Monitoring Service (MoBro) - Raspberry Pi image
# Copyright (C) 2021 ModBros
# Contact: mod-bros.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==========================================================================

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

# ==========================================================================
# Setting user permissions
# ==========================================================================

echo -n "Setting necessary permissions for modbros user..."

usermod -aG sudo modbros >/dev/null
userdel -r -f pi >/dev/null

chmod 440 ./config/010_modbros-nopasswd
cp -f ./config/010_modbros-nopasswd /etc/sudoers.d

echo " done"

# ==========================================================================
# Set file permissions
# ==========================================================================

echo -n "Setting script and file permissions..."

chmod 755 ./scripts/*.sh
chmod 755 ./service/mobro.sh

chmod 644 ./service/*.service
chmod 666 ./data/*
chmod 666 ./log/*
chmod 666 ./config/*
chmod 444 ./resources/*

echo " done"

# ==========================================================================
# update Pi
# ==========================================================================
echo -n "Updating Raspberry..."
apt-get update >/dev/null
apt-get upgrade -y >/dev/null
echo " done"

# ==========================================================================
# install dependencies
# ==========================================================================

echo "Installing dependencies"
apt-get update >/dev/null
while read dep; do
    echo -n "Installing $dep..."
    apt-get -y install "$dep" >/dev/null
    echo " done"
done <"./dependencies.txt"

# ==========================================================================
# Stop and disable access point services + bluetooth
# ==========================================================================

systemctl stop dnsmasq >/dev/null
systemctl stop hostapd >/dev/null

systemctl disable dnsmasq.service >/dev/null
systemctl disable hostapd.service >/dev/null

systemctl disable hciuart >/dev/null

# ==========================================================================
# configuring web server and resources
# ==========================================================================

echo -n "Configuring web server and resources..."

rm -rf /var/www/*

chmod +rx ./web/modbros/favicon.ico
ln -s /home/modbros/mobro-raspberrypi/web /var/www/html

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

# ==========================================================================
# Applying configuration
# ==========================================================================

echo -n "Applying configurations..."

cat ./config/config.txt >/boot/config.txt
cat ./config/cmdline.txt >/boot/cmdline.txt
cat ./config/hostname >/etc/hostname
cat ./config/hosts >/etc/hosts

echo " done"

# ==========================================================================
# swap + eeprom update
# ==========================================================================

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

# ==========================================================================
# Display drivers
# ==========================================================================

echo -n "Pulling display drivers..."

git clone https://github.com/goodtft/LCD-show.git /home/modbros/display-drivers/GoodTFT
git clone https://github.com/waveshare/LCD-show.git /home/modbros/display-drivers/Waveshare

echo " done"

echo -n "Setting permission for display drivers..."
chmod +x /home/modbros/display-drivers/GoodTFT/*show
chmod +x /home/modbros/display-drivers/Waveshare/*show
echo " done"

# ==========================================================================
# createAp
# ==========================================================================

echo -n "Installing access point script..."

rm -rf create_ap
git clone https://github.com/oblique/create_ap
chmod -R 755 create_ap
cd create_ap || exit
make install
cd ..

echo " done"

# ==========================================================================
# Cleanup
# ==========================================================================

echo -n "Removing no longer relevant packages..."
apt-get autoremove --purge -y >/dev/null
apt-get autoclean -y >/dev/null
apt-get clean -y >/dev/null
echo " done"

# ==========================================================================
# Services
# ==========================================================================

echo -n "Installing the Splashscreen + MoBro service..."

ln -s /home/modbros/mobro-raspberrypi/service/splashscreen.service /lib/systemd/system/splashscreen.service
ln -s /home/modbros/mobro-raspberrypi/service/mobro.service /lib/systemd/system/mobro.service
systemctl daemon-reload
systemctl enable splashscreen.service
systemctl enable mobro.service
systemctl stop mobro.service

echo " done"

# ==========================================================================
# Reboot
# ==========================================================================

echo "Installation completed"
echo "Rebooting..."

sleep 5

reboot

exit 0

# TODO still missing in script:
# tmpfs entry to /etc/fstab
# set php log dir to our log dir
