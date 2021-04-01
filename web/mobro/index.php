<!--
Modbros Monitoring Service (MoBro) - Raspberry Pi image
Copyright (C) 2021 ModBros
Contact: mod-bros.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>MoBro Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>

  <link rel="shortcut icon" href="../resources/favicon.ico" type="image/x-icon"/>
  <link href="../vendor/bootstrap.min.css" rel="stylesheet"/>
  <link href="../vendor/fontawesome-free-5.13.0-web/css/all.min.css" rel="stylesheet"/>

  <style>
    .confirmation-header {
      font-weight: bold;
      margin-bottom: 0.5em;
    }

    .confirmation-title {
      color: dimgrey;
    }

    .btn-wizard,
    .btn-wizard:active,
    .btn-wizard:visited {
      color: white;
      background-color: #f30;
      border-color: #f30;
      box-shadow: 0px 0px 5px black;
    }

    .btn-wizard: {
      background-color: #e13300;
      border-color: #e13300;
      color: white;
      transition: all 1s ease;
      -webkit-transition: all 1s ease;
      -moz-transition: all 1s ease;
      -o-transition: all 1s ease;
      -ms-transition: all 1s ease;
    }
  </style>

  <script src="../vendor/jquery-3.3.1.slim.min.js"></script>
  <script src="../vendor/bootstrap.bundle.min.js"></script>
</head>

<body>

<?php

include '../constants.php';
include '../util.php';

$eth = shell_exec('grep up /sys/class/net/*/operstate | grep eth0');
$ethConnected = isset($eth) && trim($eth) !== '';

$usb = shell_exec('grep up /sys/class/net/*/operstate | grep usb0');
$usbConnected = isset($usb) && trim($usb) !== '';

$ssid = shell_exec('iwgetid wlan0 -r');
$wlanConnected = isset($ssid) && trim($ssid) !== '';

$connected = $ethConnected || $usbConnected || $wlanConnected;

function getSecurityMode($mode)
{
    switch ($mode) {
        case "2a":
            return "WPA2-PSK (AES)";
        case "2t":
            return "WPA2-PSK (TKIP)";
        case "1t":
            return "WPA-PSK (TKIP)";
        case "n":
            return "None (Unsecured network)";
        case "":
        default:
            return "Automatic";
    }
}

$version = getFirstLine(Constants::FILE_VERSION, 'Unknown');

$props = parseProperties(Constants::FILE_MOBRO_CONFIG_READ);
// localization
$localization_country = getOrDefault($props['localization_country'], 'AT');
$localization_timezone = getOrDefault($props['localization_timezone'], 'UTC');

// discovery
$discovery_mode = getOrDefault($props['discovery_mode'], 'auto');
$discovery_key = getOrDefault($props['discovery_key'], 'mobro');
$discovery_ip = getOrDefault($props['discovery_ip'], '');

// network
$network_mode = getOrDefault($props['network_mode'], $ethConnected ? 'eth' : $usbConnected ? 'usb' : 'wifi');
$network_ssid = getOrDefault($props['network_ssid'], '');
$network_pw = getOrDefault($props['network_pw'], '');
$network_wpa = getOrDefault($props['network_wpa'], '');
$network_hidden = getOrDefault($props['network_hidden'], '0');

// display
$display_driver = getOrDefault($props['display_driver'], 'default');
$display_rotation = getOrDefault($props['display_rotation'], '0');
$display_screensaver = getOrDefault($props['display_screensaver'], 'disabled');
$display_delay = getOrDefault($props['display_delay'], '5');

$drivers = getAllDrivers();
$screensavers = getScreensavers();

?>

<div id="container" class="container">

  <div class="card mt-3">
    <div class="card-header">
      <div class="row">
        <div class="col">
          <img src="../resources/mobro_logo_dark.svg" width="300">
          <h4 class="text-uppercase my-3">The custom monitoring solution without stupid cables</h4>
        </div>
        <div class="col-auto">
          <img src="../resources/MoBroSoftware.png" width="275">
        </div>
      </div>
    </div>
    <div class="card-body">
      <h5 class="card-title">Hi there Bro! &#x1F60E;</h5>
      <div class="card-text">
        <p>
          Your setup of the ModBros Monitor Bro (MoBro) is almost complete.
        </p>
        <p>
          Thanks for giving our software a shot!<br/>
          We're trying hard to constantly improve the MoBro.<br/>
          Your feedback as well as suggestions for additional features and improvements are very welcome.
        </p>
        <p>
          Just visit our <a href="https://www.mod-bros.com/en/forum" target="_blank">Forum</a> or check out our new
          <a href="https://www.mod-bros.com/en/faq/mobro" target="_blank">FAQ</a> if you run into any issues.
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <h4 class="card-header">Current status / configuration</h4>
    <div class="card-body">

      <div class="row confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">Localization</div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-globe-europe"></i></span></div>
        <div class="col-4 confirmation-title">Country</div>
        <div class="col">
            <?php
            $flag = "../resources/flags/" . (file_exists("../resources/flags/" . $localization_country . ".png") ? $localization_country : '_unknown') . ".png";
            echo '<img src="' . $flag . '" height="24px" class="mr-2">' . $localization_country
            ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-clock"></i></span></div>
        <div class="col-4 confirmation-title">Timezone</div>
        <div class="col">
            <?php echo $localization_timezone ?>
        </div>
      </div>

      <hr>

      <div class="row confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">Network Configuration</div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-network-wired"></i></span></div>
        <div class="col-4 confirmation-title">Mode</div>
        <div class="col">
            <?php echo $network_mode == 'eth' ? 'Ethernet' : 'Wireless' ?>
            <?php echo $connected ? ' (Connected)' : '(Not connected)' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-wifi"></i></span></div>
        <div class="col-4 confirmation-title">SSID</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : $network_ssid ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-key"></i></span></div>
        <div class="col-4 confirmation-title">Password</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : str_repeat("*", strlen($network_pw)) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-lock"></i></span></div>
        <div class="col-4 confirmation-title">Standard</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : getSecurityMode($network_wpa) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-ghost"></i></span></div>
        <div class="col-4 confirmation-title">Hidden network</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : ($network_hidden == '0' ? "No" : "Yes") ?>
        </div>
      </div>

      <hr>

      <div class="row mt-3 confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">PC Connection</div>
      </div>
      <div class="row">
        <div class="col-1"></div>
        <div class="col-4 confirmation-title">Mode</div>
        <div class="col">
            <?php echo $discovery_mode == 'auto' ? 'Automatic discovery' : 'Static IP' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-search"></i></span></div>
        <div class="col-4 confirmation-title">Network name</div>
        <div class="col">
            <?php echo $discovery_mode == 'auto' ? $discovery_key : '<span><i class="fas fa-times"></i></span>' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-at"></i></span></div>
        <div class="col-4 confirmation-title">IP address</div>
        <div class="col">
            <?php echo $discovery_mode == 'auto' ? '<span><i class="fas fa-times"></i></span>' : $discovery_ip ?>
        </div>
      </div>

      <hr>

      <div class="row mt-3 confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">Display</div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-desktop"></i></span></div>
        <div class="col-4 confirmation-title">Driver</div>
        <div class="col">
            <?php echo $drivers[$display_driver] ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-sync-alt"></i></span></div>
        <div class="col-4 confirmation-title">Rotation</div>
        <div class="col">
            <?php echo $display_rotation ?>°
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-moon"></i></span></div>
        <div class="col-4 confirmation-title">Screensaver</div>
        <div class="col">
            <?php echo $screensavers[$display_screensaver] ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-stopwatch"></i></span></div>
        <div class="col-4 confirmation-title">Screensaver delay</div>
        <div class="col">
            <?php echo $display_screensaver == 'disabled' ? '<span><i class="fas fa-times"></i></span>' : $display_delay . ' minute(s)' ?>
        </div>
      </div>
    </div>
  </div>
  <a href="wizard.php" class="btn btn-lg btn-wizard btn-block mt-4 text-uppercase text-spaced"
     role="button">
    Configuration Wizard <span><i class="fas fa-hat-wizard"></i></span>
  </a>

  <footer class="main-footer mt-5">
    <hr>
    <div class="row">
      <img src="../resources/modbros_logo.svg" height="70" class="mr-3 ml-3">
      <p>
        Created with <span><i class="far fa-heart" style="color: #ff0066"></i></span> in Austria
        <img src="../resources/flags/AT.png" height="24"><br>
        <span><i class="far fa-copyright"></i></span> ModBros <?php echo date("Y"); ?><br/>
        Contact: <a href="https://www.mod-bros.com" target="_blank">mod-bros.com</a><br/>
      </p>
      <p class="ml-auto mr-3 font-weight-normal">v<?php echo $version ?></p>
    </div>
  </footer>
</div>

</body>
</html>