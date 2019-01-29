#!/bin/bash

# intro message like "youre about to install the modbros monitoring service"

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


# TODO intro
#echo "On a Raspberry Pi 3 with a clean install of 'Raspian Stretch with desktop'
#(excluding the recommended software) this will take up to about TODO minutes."


# =============================
# update & install dependencies
# =============================

echo -n "Updating your Raspberry..."
apt-get update > /dev/null
apt-get upgrade -y > /dev/null
echo " done"

echo -n "Installing web server and php..."
apt-get install apache2 php7.0 libapache2-mod-php7.0 -y > /dev/null
echo " done"

echo -n "Installing chrome..."
apt-get install chromium-browser -y > /dev/null
echo " done"

echo -n "Installing additional necessary tools..."
apt-get install unclutter -y > /dev/null
apt-get install curl -y > /dev/null
apt-get install hostapd dnsmasq -y > /dev/null
echo " done"

# =============================
# Stop and disable access point services
# =============================

systemctl stop dnsmasq
systemctl stop hostapd

systemctl disable dnsmasq.service
systemctl disable hostapd.service


# =============================
# copy Web
# =============================

echo -n "Copying web resources..."
rm -rf /var/www/html/modbros/*

if [[ ! -d /var/www/html/modbros ]]; then
    mkdir /var/www/html/modbros
fi

chmod +rx ./Web/favicon.ico
cp -rf ./Web/* /var/www/html/modbros/
echo " done"

echo -n "Restarting web server..."
service apache2 restart
echo " done"


# =============================
# backup original config files
# =============================

echo -n "Backup up original configuration files..."

if [[ ! -f /etc/dhcpcd.conf.orig ]]; then
    cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
fi

if [[ ! -f /etc/wpa_supplicant/wpa_supplicant.conf.orig ]]; then
    cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.orig
fi

if [[ ! -f /etc/dnsmasq.conf.orig ]]; then
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi

if [[ ! -f /etc/default/hostapd.orig ]]; then
    cp /etc/default/hostapd /etc/default/hostapd.orig
fi
echo " done"

# =============================
# Configure DHCP (dnsmasq)
# =============================

echo -n "Configuring the DHCP server (dnsmasq)..."
cp ./Config/dnsmasq.conf /etc/dnsmasq.conf
echo " done"

# =============================
# Configure access point (hostapd)
# =============================

echo -n "Configuring the access point host software (hostapd)..."

cp ./Config/hostapd.conf /etc/hostapd/hostapd.conf
sed -i -e "s/#DAEMON_CONF=\"\"/DAEMON_CONF=\"\/etc\/hostapd\/hostapd.conf\"/g" /etc/default/hostapd

echo " done"


# =============================
# Set script permissions
# =============================

echo -n "Setting script permissions..."

chmod +x ./*.sh
chmod +x ./Scripts/*.sh
chmod +x ./Service/modbros.sh
chmod 644 ./Service/modbros.service

echo " done"


# =============================
# Setting user permissions
# =============================

echo -n "Setting necessary user permissions..."

cp -f ./Config/010_wwwdata-wifi /etc/sudoers.d

chmod 0440 /etc/sudoers.d/010_wwwdata-wifi

echo " done"


# =============================
# Set custom wallpaper
# =============================

echo -n "Setting custom ModBros wallpaper..."

pcmanfm --set-wallpaper $(pwd)/Resources/modbros_wallpaper.png

echo " done"


# =============================
# Scan for available networks
# =============================

echo -n "Scanning for available wireless networks..."

iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/' > /var/www/html/modbros/networks

echo " done"


# =============================
# Service
# =============================

echo -n "Installing the ModBros service..."

cp ./Service/modbros.service /lib/systemd/system/modbros.service
systemctl daemon-reload
systemctl enable modbros.service
systemctl start modbros.service

echo " done"

# =============================
# Reboot
# =============================

echo "Installation completed"
echo "Rebooting..."

sleep 5

reboot

exit 0