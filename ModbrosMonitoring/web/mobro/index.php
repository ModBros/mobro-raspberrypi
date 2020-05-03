<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>MoBro Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>

  <link rel="shortcut icon" href="../resources/favicon.ico" type="image/x-icon"/>
  <link href="../vendor/bootstrap.min.css" rel="stylesheet"/>
  <link href="../vendor/fontawesome-free-5.13.0-web/css/all.min.css" rel="stylesheet"/>

  <link
      rel="stylesheet"
      type="text/css"
      href="//github.com/downloads/lafeber/world-flags-sprite/flags32.css"
  />

  <style>
    .confirmation-header {
      font-weight: bold;
      margin-bottom: 0.5em;
    }

    .confirmation-title {
      color: dimgrey;
    }

    .wizard-btn {
      color: white;
      background: #f30;
    }

    .wizard-btn:hover {
      color: lightgrey;
    }
  </style>

  <script src="../vendor/jquery-3.3.1.slim.min.js"></script>
  <script src="../vendor/bootstrap.bundle.min.js"></script>
</head>

<body>

<?php

include '../constants.php';

$eth = shell_exec('grep up /sys/class/net/*/operstate | grep eth0');
$ethConnected = isset($eth) && trim($eth) !== '';

$ssid = shell_exec('iwgetid wlan0 -r');
$wlanConnected = isset($ssid) && trim($ssid) !== '';

$connected = $ethConnected || $wlanConnected;

function getIfNotEof($file, $default)
{
    return $file && !feof($file) ? fgets($file) : $default;
}

function closeFile($file)
{
    if ($file) {
        fclose($file);
    }
}

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

$file = fopen(Constants::WIFI_FILE, "r");
$storedSsid = getIfNotEof($file, '');
$storedPw = getIfNotEof($file, '');
$storedCountry = getIfNotEof($file, 'AT');
$storedHidden = getIfNotEof($file, '0');
$storedWpa = getIfNotEof($file, '');
closeFile($file);

$file = fopen(Constants::VERSION_FILE, "r");
$storedVersion = getIfNotEof($file, 'Unknown');
closeFile($file);

$file = fopen(Constants::DISCOVERY_FILE, "r");
$storedDiscoveryMode = getIfNotEof($file, 'auto');
$storedKey = getIfNotEof($file, 'mobro');
$storedIp = getIfNotEof($file, '');
closeFile($file);
?>

<div id="container" class="container">

    <?php include '../includes/header.php' ?>

  <div class="card mt-3">
    <div class="card-body">
      <h5 class="card-title">Hi there!</h5>
      <div class="card-text">
        <p>
          You are seeing this configuration page, which means your setup of the ModBros Monitor Bro (MoBro) is almost
          complete.
        </p>
        <p>
          Thanks again for giving our software a shot!<br/>
          We try to steadily improve the MoBro to get it more stable and add new features.<br/>
          Your honest feedback as well as suggestions for additional features and improvements would be very welcome.
        </p>
        <p>
          Just visit our new forum on <a href="https://www.mod-bros.com" target="_blank">mod-bros.com</a> or join our
          Discord server.
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <h4 class="card-header">Current status / configuration</h4>
    <div class="card-body">
      <div class="row confirmation-header">
        <div class="col-1"></div>
        <div class="col-10">Network Configuration</div>
      </div>
      <div class="row">
        <div class="col-1"></div>
        <div class="col-4 confirmation-title">Mode</div>
        <div class="col" id="summaryNetworkMode">
            <?php echo $ethConnected ? 'Ethernet' : 'Wireless' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"></div>
        <div class="col-4 confirmation-title">Connected</div>
        <div class="col" id="summaryNetworkMode">
            <?php echo $connected ? 'Connected' : 'Not connected' ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-wifi"></i></span></div>
        <div class="col-4 confirmation-title">SSID</div>
        <div class="col" id="summarySSID">
            <?php echo $ethConnected ? '&#x1f5d9;' : $storedSsid ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-key"></i></span></div>
        <div class="col-4 confirmation-title">Password</div>
        <div class="col" id="summaryPW">
            <?php echo $ethConnected ? '&#x1f5d9;' : str_repeat("*", strlen($storedPw)) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-globe-europe"></i></span></div>
        <div class="col-4 confirmation-title">Country</div>
        <div class="col" id="summaryCountry">
            <?php echo $ethConnected ? '&#x1f5d9;' : $storedCountry ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-lock"></i></span></div>
        <div class="col-4 confirmation-title">Standard</div>
        <div class="col" id="summarySecurity">
            <?php echo $ethConnected ? '&#x1f5d9;' : getSecurityMode($storedWpa) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-ghost"></i></span></div>
        <div class="col-4 confirmation-title">Hidden network</div>
        <div class="col" id="summaryHiddenNet">
            <?php echo $ethConnected ? '&#x1f5d9;' : $storedHidden == '0' ? "No" : "Yes" ?>
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
        <div class="col" id="summaryPcConnMode">
            <?php echo $storedDiscoveryMode == 'auto' ? 'Automatic discovery' : 'Static IP' ?>
        </div>
      </div>
      <div class="row" id="summaryConKeyRow">
        <div class="col-1"><span><i class="fas fa-search"></i></span></div>
        <div class="col-4 confirmation-title">PC network name</div>
        <div class="col" id="summaryConKey">
            <?php echo $storedDiscoveryMode == 'auto' ? $storedKey : '&#x1f5d9;' ?>
        </div>
      </div>
      <div class="row" id="summaryIpRow">
        <div class="col-1"><span><i class="fas fa-at"></i></span></div>
        <div class="col-4 confirmation-title">IP address</div>
        <div class="col" id="summaryIp">
            <?php echo $storedDiscoveryMode == 'auto' ? '&#x1f5d9;' : $storedIp ?>
        </div>
      </div>
    </div>
  </div>

  <a href="wizard.php" class="btn btn-lg btn-block mt-4 wizard-btn" role="button">
    Configuration Wizard <span><i class="fas fa-hat-wizard"></i></span>
  </a>

    <?php include '../includes/footer.php' ?>
</div>

</body>
</html>