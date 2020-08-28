# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [v11](https://github.com/ModBros/mobro-raspberrypi/compare/v10...v11) - 2020-08-29

### Added

* added readme
* added changelog
* support for display rotation
* flags in country selection
* configurable screensaver
* timezone configuration
* added API calls for configuration and service 

### Changed

* reduced recurring background logging
* multiple connection attempts in background check  
(to avoid disconnection after just one bad request)
* better styling for select items
* merged MoBro specific configurations into a single file

### Fixed

* Pi didn't reconnect to PC after it lost connection once 


## [v10](https://github.com/ModBros/mobro-raspberrypi/compare/v9...v10) - 2020-05-21

### Fixed

* fixed connection over static IP
* multiple connections to the PC application were opened in some cases 

## [v9](https://github.com/ModBros/mobro-raspberrypi/compare/v8...v9) - 2020-05-17

### Added

* all new configuration wizard
* enabled display driver installation via web configuration
* enable configuration of wifi country (needed for correct 5G frequency bands)
* support for hidden wifi networks
* expose additional wifi settings via configuration (WPA version, encryption method)
* support for connection via static IP instead of service discovery
* set 'noatime' for /var/run, /var/log, /boot and /  
(to avoid writing to SD card every time a file is read) 
* added display resolution as parameter to mobro url
* added device type to mobro url
* added license

### Changed

* major re-design of the configuration page
* disabled swapping
* mount /var/run and /var/log as tmpfs 
* updated _config.txt_
* major project restructuring
* renamed service
* adapted parameters for log endpoint
* styling adjustments

### Fixed

* fixed hotspot creation in case no display is connected
* only show distinct SSIDs in configuration
* set uuid (=mac address) based on current network mode


## [v8](https://github.com/ModBros/mobro-raspberrypi/compare/v7...8) - 2020-04-19

### Changed

* removed Wifi password from configuration hotspot
* updated _config.txt_
* cleanup of dependencies

### Fixed

* unblock the Wifi interface on startup
* fixed CPU frequency bug on Pi 4

## [v7](https://github.com/ModBros/mobro-raspberrypi/compare/v7...v6) - 2020-03-29

### Added

* restful api endpoint to shutdown or restart the Pi 
* restful api endpoint to retrieve load data (top)
* restful api endpoint to retrieve current Pi temperature
* new dependencies: _xserver-xorg-video-fbturbo, git, secure-delete_

### Fixed

* removed chromium _use-gl_ flag as it caused issues with GPIO displays
* re-added lighttpd to autostart to make log available if service fails to start

## [v6](https://github.com/ModBros/mobro-raspberrypi/compare/v6...v5) - 2020-03-17

### Added

* added LAN support
* expose version via rest endpoint
* included waveshare display drivers on image
* added uuid to mobro url

### Changed

* adapted _config.txt_
* disable screen turning off
* re-branded to use MoBro logo
* update to log rest endpoint
* code refactoring and project restructuring


### Fixed

* fixed stopping of processes
* workaround for chromium update bug
* fixed bug on changing the discovery key


## [v5](https://github.com/ModBros/mobro-raspberrypi/compare/v5...v4) - 2019-11-11

### Changed

* changed hostname to 'mobro-raspberrypi'
* added MoBro logo to splash screen
* disabled automatic system upgrade as it caused issues
* adapted _config.txt_


## [v4](https://github.com/ModBros/mobro-raspberrypi/compare/v4...v3) - 2019-09-03

### Changed

* minor change to project structure
* tweaks to timeouts and chromium flags

### Fixed

* search for available networks
* handle access point creation failure
* do not write wifi pw to log
* fixed file permissions


## [v3](https://github.com/ModBros/mobro-raspberrypi/compare/v3...v2) - 2019-07-21

### Added

* update to Raspian buster
* significantly reduced image size
* check for availabilty of wireless interface on startup

### Changed

* adapted _config.txt_
* reduced swapping


## [v2](https://github.com/ModBros/mobro-raspberrypi/compare/v2...v1) - 2019-06-12

### Added

* automatic system upgrade
* expose log via rest endpoint

### Changed

* huge performance uplift by using images and feh instead of local pages in chrome
* new style of visible pages
* added version number to splash screen
* log format
* more parallel requests in service discovery


### Fixed

* bug resulting in endless loop waiting for CPU usage to come down
* bug in startup sequence
* service discovery bug
* various in wifi and hotspot handling


## [v1](https://github.com/ModBros/mobro-raspberrypi/compare/v1...v0) - 2019-03-13

### Changed

* significant speed up (no longer restarting chrome on every page change)
* various smaller general improvements and adaptations
* more parallel requests in service discovery

### Fixed

* various bugfixes


## v0 - 2019-02-13

### Added

* Initial release
