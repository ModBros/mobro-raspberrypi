#!/bin/bash

# ==========================================================
# Modbros Monitoring Service - Raspberry Pi
#
# installation script
# (intended for and tested only on clean Raspbian Buster lite)
#
# Created with <3 in Austria by: (c) ModBros 2019
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

echo -n "Adding user and setting necessary permissions..."

if ! id "modbros" >/dev/null 2>&1; then
    adduser modbros --gecos "ModBros,,," --disabled-password
    echo "modbros:modbros" | chpasswd
    usermod -aG sudo modbros
    userdel -r -f pi
fi

cp -f ./config/010_modbros-nopasswd /etc/sudoers.d
chmod 440 /etc/sudoers.d/010_modbros-nopasswd

echo " done"


# ==========================================================
# update Pi
# ==========================================================

echo -n "Updating Raspberry..."
apt-get update > /dev/null
apt-get dist-upgrade -y > /dev/null
echo " done"


# ==========================================================
# install dependencies
# ==========================================================

echo "Installing dependencies:"
while read dep; do
    echo -n "Installing $dep..."
    apt-get -y install $dep > /dev/null
    echo " done"
done < "./dependencies.txt"


# ==========================================================
# Stop and disable access point services
# ==========================================================

systemctl stop dnsmasq > /dev/null
systemctl stop hostapd > /dev/null

systemctl disable dnsmasq.service > /dev/null
systemctl disable hostapd.service > /dev/null


# ==========================================================
# configuring web server and resources
# ==========================================================

echo -n "Configuring web server and resources..."

rm -rf /var/www/*

chmod +rx ./web/modbros/favicon.ico
ln -s /home/modbros/ModbrosMonitoring/web /var/www/html
ln -s /home/modbros/ModbrosMonitoring/data/ssids.txt /home/modbros/ModbrosMonitoring/web/modbros/networks

sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g" /etc/php/7.3/fpm/php.ini
cat ./config/15-fastcgi-php.conf > /etc/lighttpd/conf-available/15-fastcgi-php.conf

lighttpd-enable-mod fastcgi > /dev/null
lighttpd-enable-mod fastcgi-php > /dev/null

echo " done"

echo -n "Restarting web server..."
service lighttpd force-reload > /dev/null
service lighttpd restart > /dev/null
systemctl enable lighttpd.service > /dev/null
echo " done"


# ==========================================================
# Set permissions
# ==========================================================

echo -n "Setting script and file permissions..."

chmod 755 ./scripts/*.sh
chmod 755 ./service/modbros.sh

chmod 644 ./service/modbros.service
chmod 666 ./data/*
chmod 666 ./log/*
chmod 666 ./resources/*
chmod 666 ./config/*

echo " done"


# ==========================================================
# Scan for available networks
# ==========================================================

#echo -n "Scanning for available wireless networks..."
#
#iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/' > ./web/modbros/networks
#
#echo " done"


# ==========================================================
# Display drivers
# ==========================================================

echo -n "Pulling display drivers..."

rm -rf LCD-show
git clone https://github.com/goodtft/LCD-show.git /home/modbros/Display-Drivers
chmod 755 /home/modbros/Display-Drivers/*.sh
cp -f ./config/config.txt /home/modbros/Display-Drivers/boot/config-nomal.txt
cp -f ./config/config.txt /home/modbros/Display-Drivers/boot/config-noobs-nomal.txt

echo " done"


# ==========================================================
# createAp
# ==========================================================

echo -n "Installing access point script..."

rm -rf create_ap
git clone https://github.com/oblique/create_ap
chmod -R 755 create_ap
cd create_ap
make install
cd ..
rm -rf create_ap

echo " done"

# ==========================================================
# Cleanup
# ==========================================================

echo -n "Removing no longer relevant packages..."
apt-get purge git make -y > /dev/null
apt-get autoremove --purge -y > /dev/null
apt-get autoclean -y > /dev/null
apt-get clean -y > /dev/null
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
