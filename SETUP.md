# Setup Guide

Step-by-step guide on how to set up all the services and code from this repository on a Raspberry Pi.  
This represents the exact same way the pre-built downloadable image provided by us (ModBros) is set up.

Requirements:

* any Raspberry Pi model
* micro-SD card with at least 4GB of space

All the commands have to be executed as root or by using 'sudo'

### Install Raspberry Pi OS

Download the latest version of the
official [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/)  
Flash the image onto an SD card using
e.g. [Raspberry Pi Imager](https://www.raspberrypi.org/blog/raspberry-pi-imager-imaging-utility/)
or [balena Etcher](https://www.balena.io/etcher/)

### Set up partitions

Set up a separate partition for /home. You can do this by using [gparted](https://gparted.org/)

We will be using OverlayFS for the root partition. The service needs to be able to re-mount the /home partition with
write permissions without having to reboot in order to be able to occasionally alter configuration files.  
This wouldn't be possible if /home was located on the OverlayFS partition, so we need to create a separate one.

Once you're done the command **_fdisk -lu_** should return something like this:

```
Device         Boot   Start     End Sectors  Size Id Type
/dev/mmcblk0p1         8192  532479  524288  256M  c W95 FAT32 (LBA)
/dev/mmcblk0p2       532480 6823935 6291456    3G 83 Linux
/dev/mmcblk0p3      6823936 7348223  524288  256M  5 Extended
/dev/mmcblk0p5      6825984 7348223  522240  255M 83 Linux
```

Now we need to temporarly mount our new /home partition (/dev/mmcblk0p5 in this example) and copy over the existing user
folders.  
After that we can remove them on the old partition.

```bash
mount /dev/mmcblk0p5 /mnt
cp /home/* /mnt/ -rp
rm /home/* -r
```

Then proceed to edit the **/etc/fstab** which then should then look something like this:

```
proc                  /proc           proc    defaults             0       0
/dev/mmcblk0p1        /boot           vfat    defaults,noatime,ro  0       2
/dev/mmcblk0p2        /               ext4    defaults,noatime     0       1
/dev/mmcblk0p5        /home           ext4    defaults,noatime,ro  0       0
```

Now reboot for the changes to take effect

```bash
reboot
```

Now (after the reboot) the /home and /boot partitions will be mounted read-only like we just specified in the /etc/fstab
file.  
In order to proceed the setup we need to remount them with write permissions:

```bash
mount -o remount,rw /home
mount -o remount,rw /boot
```

### Update Raspberry Pi

Make sure everything on the Raspberry Pi is on the latest version

```bash
apt-get update
apt-get upgrade -y
```

### Disable swap

Since we will be using OverlayFS + read-only mounting we won't be able to use a swap file.  
Disable swapping completely:

```bash
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
apt purge -y dphys-swapfile
```

### Setup user

Creating our own 'modbros' user which will run our services.  
Since there's no need for the default 'pi' user any more we will remove it.

```bash
adduser modbros
usermod -aG sudo modbros
userdel -r -f pi
```

Logout and login again using the newly created user.

### Install dependencies

Install all of the required dependencies. This might take a bit of time.

```bash
apt-get -y install lighttpd php7.3-fpm libterm-readline-gnu-perl xserver-xorg xserver-xorg-video-fbturbo x11-xserver-utils xinit matchbox-window-manager libgles2-mesa chromium-browser xwit xdotool curl arp-scan util-linux procps iproute2 iw iptables net-tools hostapd dnsmasq git make feh rng-tools secure-delete fbi busybox-syslogd
```

### Remove unused packages

We just installed the busybox in-memory logger to replace the standard syslog output. So we no longer need these
packages

```bash
apt purge -y logrotate rsyslog
apt autoremove -y
```

### Stop and disable access point services

Those will be started by the 'mobro' service when they are needed. We don't need to have them running or enabled

```bash
systemctl stop dnsmasq
systemctl stop hostapd
systemctl disable dnsmasq.service 
systemctl disable hostapd.service 
```

### Install createAp

[create_ap](https://github.com/oblique/create_ap) is used the manage the configuration hotspot

```bash
cd /home/modbros
git clone https://github.com/oblique/create_ap
chmod -R 755 create_ap
cd create_ap
make install
```

### Checkout MoBro repository

Now finally also check out the repository this setup guide is in and for ;)

```bash
git checkout https://github.com/ModBros/mobro-raspberrypi.git
cd mobro-raspberrypi
```

### Set file permissions

```bash
chmod 755 ./scripts/*.sh
chmod 755 ./service/*.sh

chmod 644 ./service/*.service

chmod 666 ./config/*
chmod 444 ./resources/*

chmod 440 ./config/010_modbros-nopasswd
chmod 440 ./config/010_wwwdata-scripts
cp -f ./config/010_modbros-nopasswd /etc/sudoers.d
cp -f ./config/010_wwwdata-scripts /etc/sudoers.d
```

### Configure web server

Configure PHP and the webserver that is used to host the configuration page and REST interface

```bash
rm -rf /var/www/*

chmod +rx ./web/modbros/favicon.ico
ln -s /home/modbros/mobro-raspberrypi/web /var/www/html

sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g" /etc/php/7.3/fpm/php.ini
cat ./config/15-fastcgi-php.conf >/etc/lighttpd/conf-available/15-fastcgi-php.conf

lighttpd-enable-mod fastcgi 
lighttpd-enable-mod fastcgi-php 

service lighttpd force-reload 
service lighttpd restart 
systemctl enable lighttpd.service 

cp -f ./config/010_wwwdata-scripts /etc/sudoers.d
chmod 440 /etc/sudoers.d/010_wwwdata-scripts
```

### Applying configurations

```bash
cat ./config/config.txt > /boot/config.txt
cat ./config/cmdline.txt > /boot/cmdline.txt
cat ./config/hostname > /etc/hostname
cat ./config/hosts > /etc/hosts
cat ./config/.bashrc >> /home/modbros/.bashrc
cat ./config/99-fbturbo.conf > /usr/share/X11/xorg.conf.d/99-fbturbo.conf
```

### Set up display drivers

Check out the 2 driver collections that will be installable from the configuration wizard.  
Since we need to execute some code after applying the driver, we need to also remove the reboot commands from all the
driver scripts.

```bash
git clone https://github.com/goodtft/LCD-show.git /home/modbros/display-drivers/GoodTFT
git clone https://github.com/waveshare/LCD-show.git /home/modbros/display-drivers/Waveshare

chmod +x /home/modbros/display-drivers/GoodTFT/*show
chmod +x /home/modbros/display-drivers/Waveshare/*show

sed -i '/reboot/d' /home/modbros/display-drivers/GoodTFT/*show
sed -i '/reboot/d' /home/modbros/display-drivers/Waveshare/*show
```

### Set up splashscreen (optional)

Dedicated service to display a splashscreen sooner, even before the actual MoBro service is started

```bash
cp /home/modbros/mobro-raspberrypi/service/splashscreen.service /lib/systemd/system/splashscreen.service

systemctl disable getty@tty1
systemctl daemon-reload
systemctl enable splashscreen.service
```

### Set up service to persist logs (optional)

Dedicated service that will remount the /home partition and copy the current log file over.  
This is required if you want to persist the log file since it is only created and lives in the /tmp directory

```bash
cp /home/modbros/mobro-raspberrypi/service/shutdownlog.service /lib/systemd/system/shutdownlog.service

systemctl daemon-reload
systemctl enable shutdownlog.service
```

### Set up MoBro service

The main MoBro services that does most of the actual work

```bash
cp /home/modbros/mobro-raspberrypi/service/mobro.service /lib/systemd/system/mobro.service

systemctl daemon-reload
systemctl enable mobro.service
```

### Reboot

```bash
reboot
```