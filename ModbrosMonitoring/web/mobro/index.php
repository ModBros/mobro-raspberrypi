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

    .btn-wizard:hover {
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

$eth = shell_exec('grep up /sys/class/net/*/operstate | grep eth0');
$ethConnected = isset($eth) && trim($eth) !== '';

$ssid = shell_exec('iwgetid wlan0 -r');
$wlanConnected = isset($ssid) && trim($ssid) !== '';

$connected = $ethConnected || $wlanConnected;

function getIfNotEof($file, $default)
{
    return $file && !feof($file) ? trim(fgets($file)) : $default;
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

$file = fopen(Constants::FILE_VERSION, "r");
$version = getIfNotEof($file, '');
closeFile($file);

$file = fopen(Constants::FILE_WIFI, "r");
$netMode = getIfNotEof($file, '');
$storedSsid = getIfNotEof($file, '');
$storedPw = getIfNotEof($file, '');
$storedCountry = getIfNotEof($file, 'AT');
$storedHidden = getIfNotEof($file, '0');
$storedWpa = getIfNotEof($file, '');
closeFile($file);

$file = fopen(Constants::FILE_VERSION, "r");
$storedVersion = getIfNotEof($file, 'Unknown');
closeFile($file);

$file = fopen(Constants::FILE_DISCOVERY, "r");
$storedDiscoveryMode = getIfNotEof($file, 'auto');
$storedKey = getIfNotEof($file, 'mobro');
$storedIp = getIfNotEof($file, '');
closeFile($file);
?>

<div id="container" class="container">

  <div class="card mt-3">
    <div class="card-header">
      <div class="row">
        <div class="col">
          <img src="../resources/mobro-logo.svg" width="300">
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
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : $storedSsid ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-key"></i></span></div>
        <div class="col-4 confirmation-title">Password</div>
        <div class="col" id="summaryPW">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : str_repeat("*", strlen($storedPw)) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-globe-europe"></i></span></div>
        <div class="col-4 confirmation-title">Country</div>
        <div class="col" id="summaryCountry">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : $storedCountry ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-lock"></i></span></div>
        <div class="col-4 confirmation-title">Standard</div>
        <div class="col" id="summarySecurity">
            <?php echo $ethConnected ? '<span><i class="fas fa-times"></i></span>' : getSecurityMode($storedWpa) ?>
        </div>
      </div>
      <div class="row">
        <div class="col-1"><span><i class="fas fa-ghost"></i></span></div>
        <div class="col-4 confirmation-title">Hidden network</div>
        <div class="col" id="summaryHiddenNet">
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
        <div class="col" id="summaryPcConnMode">
            <?php echo $storedDiscoveryMode == 'auto' ? 'Automatic discovery' : 'Static IP' ?>
        </div>
      </div>
      <div class="row" id="summaryConKeyRow">
        <div class="col-1"><span><i class="fas fa-search"></i></span></div>
        <div class="col-4 confirmation-title">Network name</div>
        <div class="col" id="summaryConKey">
            <?php echo $storedDiscoveryMode == 'auto' ? $storedKey : '<span><i class="fas fa-times"></i></span>' ?>
        </div>
      </div>
      <div class="row" id="summaryIpRow">
        <div class="col-1"><span><i class="fas fa-at"></i></span></div>
        <div class="col-4 confirmation-title">IP address</div>
        <div class="col" id="summaryIp">
            <?php echo $storedDiscoveryMode == 'auto' ? '<span><i class="fas fa-times"></i></span>' : $storedIp ?>
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
      <img src="../resources/modbros-logo.svg" height="70" class="mr-3 ml-3">
      <p>
        Created with <span><i class="far fa-heart" style="color: #ff0066"></i></span> in Austria
        <img src="../resources/austria.svg" height="12px"><br>
        <span><i class="far fa-copyright"></i></span> ModBros <?php echo date("Y"); ?><br/>
        Contact: <a href="https://www.mod-bros.com" target="_blank">mod-bros.com</a><br/>
      </p>
      <p class="ml-auto mr-3 font-weight-normal">v<?php echo $version ?></p>
    </div>
  </footer>
</div>

</body>
</html>