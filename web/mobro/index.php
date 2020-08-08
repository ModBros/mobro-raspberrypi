<!--
Modbros Monitoring Service (MoBro) - Raspberry Pi image
Copyright (C) 2020 ModBros
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

$ssid = shell_exec('iwgetid wlan0 -r');
$wlanConnected = isset($ssid) && trim($ssid) !== '';

$connected = $ethConnected || $wlanConnected;

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

$props = parseProperties(Constants::FILE_NETWORK);
$storedNetworkMode = getOrDefault($props['mode'], 'wifi');
$storedSsid = getOrDefault($props['ssid'], '');
$storedPw = getOrDefault($props['pw'], '');
$storedHidden = getOrDefault($props['hidden'], '0');
$storedWpa = getOrDefault($props['wpa'], '');

$props = parseProperties(Constants::FILE_DISCOVERY);
$storedDiscoveryMode = getOrDefault($props['mode'], 'auto');
$storedKey = getOrDefault($props['key'], 'mobro');
$storedIp = getOrDefault($props['ip'], '');

$props = parseProperties(Constants::FILE_DISPLAY);
$storedDriver = getOrDefault($props['driver'], 'hdmi');
$storedRotation = getOrDefault($props['rotation'], '0');
$storedScreensaver = getOrDefault($props['screensaver'], 'disabled');
$storedDelay = getOrDefault($props['delay'], '1');

$props = parseProperties(Constants::FILE_LOCALIZATION);
$storedCountry = getOrDefault($props['country'], 'AT');
$storedTimezone = getOrDefault($props['timezone'], 'UTC');

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
            $flag = "../resources/flags/" . (file_exists("../resources/flags/" . $storedCountry . ".png") ? $storedCountry : '_unknown') . ".png";
            echo '<img src="' . $flag . '" height="24px" class="mr-2">' . $storedCountry
            ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-clock"></i></span></div>
        <div class="col-4 confirmation-title">Timezone</div>
        <div class="col">
            <?php echo $storedTimezone ?>
        </div>
      </div>

      <hr>

      <div class="row confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">Network Configuration</div>
      </div>
      <div class="row">
        <div class="col-1"></div>
        <div class="col-4 confirmation-title">Mode</div>
        <div class="col">
            <?php echo $ethConnected ? 'Ethernet' : 'Wireless' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"></div>
        <div class="col-4 confirmation-title">Connected</div>
        <div class="col">
            <?php echo $connected ? 'Connected' : 'Not connected' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-wifi"></i></span></div>
        <div class="col-4 confirmation-title">SSID</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : $storedSsid ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-key"></i></span></div>
        <div class="col-4 confirmation-title">Password</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : str_repeat("*", strlen($storedPw)) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-lock"></i></span></div>
        <div class="col-4 confirmation-title">Standard</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : getSecurityMode($storedWpa) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-ghost"></i></span></div>
        <div class="col-4 confirmation-title">Hidden network</div>
        <div class="col">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : ($storedHidden == '0' ? "No" : "Yes") ?>
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
            <?php echo $storedDiscoveryMode == 'auto' ? 'Automatic discovery' : 'Static IP' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-search"></i></span></div>
        <div class="col-4 confirmation-title">Network name</div>
        <div class="col">
            <?php echo $storedDiscoveryMode == 'auto' ? $storedKey : '<span><i class="fas fa-times"></i></span>' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-at"></i></span></div>
        <div class="col-4 confirmation-title">IP address</div>
        <div class="col">
            <?php echo $storedDiscoveryMode == 'auto' ? '<span><i class="fas fa-times"></i></span>' : $storedIp ?>
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
            <?php echo $drivers[$storedDriver] ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-sync-alt"></i></span></div>
        <div class="col-4 confirmation-title">Rotation</div>
        <div class="col">
            <?php echo $storedRotation ?>°
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-moon"></i></span></div>
        <div class="col-4 confirmation-title">Screensaver</div>
        <div class="col">
            <?php echo $screensavers[$storedScreensaver] ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-stopwatch"></i></span></div>
        <div class="col-4 confirmation-title">Screensaver delay</div>
        <div class="col">
            <?php echo $storedScreensaver == 'disabled' ? '<span><i class="fas fa-times"></i></span>' : $storedDelay . ' minute(s)' ?>
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