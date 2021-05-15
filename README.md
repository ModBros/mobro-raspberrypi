# mobro-raspberrypi

![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/ModBros/mobro-raspberrypi?label=version)
![GitHub](https://img.shields.io/github/license/ModBros/mobro-raspberrypi)
[![Discord](https://img.shields.io/discord/620204412706750466?label=Discord)](https://discord.com/invite/DSNX4ds)
[![FAQ](https://img.shields.io/badge/-FAQ-f30.svg)](https://www.mod-bros.com/en/faq/mobro)
[![YouTube](https://img.shields.io/badge/-YouTube-red.svg)](https://www.youtube.com/channel/UCUU5DVHRzQEnGPVS5WKRg6A)
[![Download](https://img.shields.io/badge/-Download-brightgreen.svg)](https://www.mod-bros.com/en/projects/mobro)

**Official Raspberry Pi image of MoBro**

![MoBro logo + header](./images/readme_header.png)

## Table of Contents

* [What is MoBro?](#what-is-mobro)
* [Windows application](#windows-application)
* [Raspberry Pi image](#raspberry-pi-image)
  * [What does this image do?](#what-does-this-image-do)
  * [Download and install](#download-and-install)
  * [Supported Raspberry Pi Models](#supported-raspberry-pi-models)
* [Technical documentation](#technical-documentation)
  * [File system](#file-system)
  * [Configuration](#configuration)
  * [REST Api](#rest-api)
  * [Logging](#logging)

Feel free to visit our [Forum](https://www.mod-bros.com/en/forum)
or [Discord](https://discord.com/invite/DSNX4ds) if you run into issues or questions that are not already answered here.  
Feedback as well as suggestions for additional features and improvements are always welcome!

# What is MoBro?

The Monitor Bro (MoBro) by ModBros collects monitoring data about your installed hardware locally on your PC.  
It is designed and built to take in data from multiple different monitoring applications
(= data sources or plugins) such as HWiNFO and others.  
It combines them into a single UI while letting you choose which values of which source you are interested in and want
to see.  
All configurable via an easy customization interface.

__Defining features__:

* Reading data from different sources
* Customizable interface displaying the data YOU are interested in
* Your data does not leave your network and is shared with no one
* Displaying data on various client devices (Raspberry Pi, Android phones,...) located anywhere in your house
* Different customizable theme for each of your devices

# Windows application

The running MoBro PC application is required for this Raspberry Pi project.  
Currently only available for Windows ([Download here](https://www.mod-bros.com/en/projects/mobro)).

[![Windows app explanation video](http://img.youtube.com/vi/bLwOTQ8MW7s/0.jpg)](http://www.youtube.com/watch?v=bLwOTQ8MW7s)


# Raspberry Pi image

This Raspberry Pi image acts as a client device to the MoBro Windows application to which it connects.  
It provides an easy and cost-effective way to set up a wireless device displaying the PC's stats in realtime anywhere in
the house.

[![Installation video](http://img.youtube.com/vi/iebBcQuBhYs/0.jpg)](http://www.youtube.com/watch?v=iebBcQuBhYs)

## What does this image do?

This custom pre-configured image provides an easy way to setup the Raspberry Pi as a MoBro monitoring device.  
It is ready to be flashed onto a micro SD card and put straight to use in a Raspberry Pi.   
All the required configuration is done via an easy-to-use web based configuration wizard.

No coding skills or Linux experience required.

## Download and install

Detailed instructions on how to download flash and setup the image can be found here:  
[Download and flash](https://www.mod-bros.com/en/faq/mobro/raspberry/download),
[Setup](https://www.mod-bros.com/en/faq/mobro/raspberry/setup)

## Supported Raspberry Pi Models

This image is ready to run on all Raspberry Pi models.  
For wireless operation a model with built-in Wifi is required.

[Supported models and known limitations](https://www.mod-bros.com/en/faq/mobro/raspberry/supported-hardware)


# Technical documentation

This image is based on the official [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/).

Changelog can be found here: [Changelog](./CHANGELOG.md)  
Setup guide for this repository: [Setup](./SETUP.md)

The mobro service ([mobro.sh](./service/mobro.sh)) is the centerpiece of this image and handles all the automation and
heavy lifting.  
User configuration is done via a simple web based wizard hosted by Lighttpd.

## File system

The disk of this image is split up into three partitions: / (root), /boot and /mobro

### root (OverlayFS)

The __root__ partition is set up for [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS). So the underlying partition is
mounted read-only with an in memory read/write partition overlay on top if it.  
As a consequence, all file changes while running are only stored in the overlay in RAM and not actually written to the
SD card and therefore will be gone upon shutdown/reboot.  
This has the following benefits:
* no write operations to the SD card, which greatly extends its lifespan
* reduced risk of data corruption in case the Pi is not shut down correctly (e.g. just cutting the power)
* guarantee that the Pi is in the exact same state on every boot

However, this approach also complicates certain things:  
All custom modifications to configuration files on the root partition will be lost upon reboot or shutdown. In order to
persist custom changes you will need to:
* disable OverlayFS  
  just call '[fsmount.sh](./scripts/fsmount.sh) --rw root' to disable OverlayFS for the next boot
* temporarily disable the mobro service  
  the service would automatically re-enable OverlayFS and reboot before we can do anything if we don't disable it  
  create a file named 'skip_service' on the /mobro partition to skip the service on the next boot 
  (just execute 'touch /mobro/skip_service')
* reboot
* apply your custom changes
* enable the service again by removing the flag  
  just execute 'rm -f /mobro/skip_service'
* enable OverlayFS again  
  just execute '[fsmount.sh](./scripts/fsmount.sh) --ro root'
* reboot again

Note:  
The procedure explained above is only required if you need to install software or apply custom changes that are
not covered by our configuration wizard. For all the changes done through our configuration wizard, the above scenario 
is handled automatically by our scripts and requires no additional user handling or input. Just hist 'apply' as usual 
and you're good ;)

If you wish to disable OverlayFS altogether you can do this from the 'Advanced customization' step in the configuration 
wizard.

### /boot + /mobro
The __/boot__ partition is mounted read-only per default. In case you need to manually alter e.g. the config.txt file you
first need to remount /boot with write permissions.  
Simply call '[fsmount.sh](./scripts/fsmount.sh) --status' to see the current mounting status and
'[fsmount.sh](./scripts/fsmount.sh) --rw boot' to remount the /boot partition with write permissions.

__/mobro__ is a small dedicated partition that is mounted with write permissions and is used to store configuration
files, flags etc. required by the mobro service.

## Configuration

The MoBro specific configuration is stored as a simple property file.  
Current settings and their meaning:

| Setting                    | Description |
| :------------------------- | :---------- |
| localization_country       | [ISO 3166 country code](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) |
| localization_timezone      | timezone name as listed in [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| network_mode               | 'eth', 'wifi' or 'usb' (Pi Zero only) |
| network_ssid               | the network SSID to connect to (only in wifi mode) |
| network_pw                 | the network password (only in wifi mode) |
| network_wpa                | the WPA mode. one of: 2a, 2t, 1t, n (optional, only in wifi) |
| network_hidden             | whether the network is hidden (only in wifi) |
| discovery_mode             | 'auto' (default) or 'manual'|
| discovery_key              | the discovery key as configured in the MoBro deskop application (default=mobro) |
| discovery_ip               | the static IP address of the PC (only in 'manual' network mode) |
| display_driver             | 'default', 'pi7' or path to the driver install executable |
| display_rotation           | one of: 0 (default), 90, 180, 270 |
| display_screensaver        | 'disabled' or screensaver file |
| display_delay              | delay for the screensaver in minutes, default=5 |
| advanced_overclock_mode    | overclock configuration to apply, default=none |
| advanced_overclock_consent | explicit consent to overclocking. has to be set to '1' for the overclock to be applied |
| advanced_fs_dis_overlayfs  | flag to disable the OverlayFS, default = 0 |
| advanced_fs_persist_log    | flag to enable persistent logging, default = 0 |

Just altering the values in the configuration file is NOT enough. The configuration file has to be applied by executing
the [apply_new_config.sh](./scripts/apply_new_config.sh) script and passing the config file as parameter.

Example configuration:

```
localization_country=AT
localization_timezone=UTC
network_mode=
network_ssid=
network_pw=
network_wpa=
network_hidden=0
discovery_mode=auto
discovery_key=mobro
discovery_ip=
display_driver=default
display_rotation=0
display_screensaver=clock_date.php
display_delay=0
```

In addition, it is possible to pass a 2nd configuration file to [apply_new_config.sh](./scripts/apply_new_config.sh)
that contains custom entries that will be added to the config.txt file. E.g.:

```
temp_limit=75
arm_freq=1000
over_voltage=0
```

Order of application for changes to the config.txt file:

1. default config.txt file
2. display driver installation
3. overclock settings (advanced_overclock from MoBro config file)
4. custom overrides/additions (from the 2nd config file mentioned above)
5. OverlayFS settings

## REST Api

For debug purposes the MoBro Raspberry Pi image exposes a very basic REST API.  
This API is subject to change.

|     | Route              | Description                                                                | Format | Parameters |
| --- | :----------------- | :------------------------------------------------------------------------- | :----- | :--------- |
| GET | /api               | returns the API documentation                                              | text   | - |
| GET | /api/version       | returns the current version number                                         | text   | - |
| GET | /api/log           | returns the current logfile                                                | text   | *lines*: only most recent n lines<br> *count*: log files of previous n boots (max = 10, default = 0) |
| GET | /api/syslog        | returns the current syslog file                                            | text   | - |
| GET | /api/top           | returns the output of the "top" command. i.e.: CPU/RAM Usage, Processes... | text   | - |
| GET | /api/configuration | returns the current configuration                                          | text   | - |
| GET | /api/hwstats       | stats of the hardware components (e.g. CPU/RAM usage, temperature,...)     | json   | *filter*: cpu,memory,filesystem (default=none) |
| PUT | /api/restart       | restarts the Raspberry Pi                                                  | -      | *delay*: minutes before restart (default: 0) |
| PUT | /api/shutdown      | shuts down the Raspberry Pi                                                | -      | *delay*: minutes before shutdown (default: 0) |
| PUT | /api/service       | starts, stops or restarts the MoBro service                                | -      | *action*: start, stop, restart (default) |


## Logging

This image uses in-memory busybox-syslogd. The current log file can be viewed by calling 'logread' or through the
respective ['syslog' REST endpoint](#rest-api).

The mobro specific log file containing the log output of all our services and scripts is located at __/tmp/mobro_log__
and can also be pulled through the respective ['log' REST endpoint](#rest-api).

The log file is not written to the SD-card and therefore not persisted. To persist log files for debug purposes, the
[shutdownlog](./service/shutdownlog.sh) service can be enabled in the configuration wizard. It will automatically copy
the current log file over to '/mobro/log' before regular shutdowns and rotate them to keep the most recent 10 files.

