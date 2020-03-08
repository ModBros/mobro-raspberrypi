<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>MoBro Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <link rel="shortcut icon" href="../resources/favicon.ico" type="image/x-icon"/>
  <link href="../bootstrap.min.css" rel="stylesheet"/>
  <link href="../bootstrap.min.js" rel="script">
</head>

<body>

<?php

include '../constants.php';

$eth = shell_exec('grep up /sys/class/net/*/operstate | grep eth0');
$ethConnected = isset($eth) && trim($eth) !== '';

$ssid = shell_exec('iwgetid wlan0 -r');
$wlanConnected = isset($ssid) && trim($ssid) !== '';

$connected = $ethConnected || $wlanConnected;

if ($file = fopen(Constants::KEY_FILE, "r")) {
    if (!feof($file)) {
        $key = fgets($file);
    }
    fclose($file);
}
if ($file = fopen(Constants::VERSION_FILE, "r")) {
    if (!feof($file)) {
        $version = fgets($file);
    }
    fclose($file);
}
?>

<div id="container" class="container">

  <?php include '../includes/header.php' ?>

  <div class="card mt-3">
    <div class="card-body">
      <h5 class="card-title">Hi there! &#x1F600;</h5>
      <div class="card-text">
        <p>
          You are seeing this configuration page, which means your setup of the ModBros Monitor Bro (MoBro) is almost
          complete.
        </p>
        <p class="m-0">
          Thanks for giving our software a shot!<br/>
          We try to steadily improve the MoBro to get it more stable and add new features.<br/>
          As this is our first adventure into the PC stats monitoring territory, both your honest feedback as well as
          suggestions for future improvements would be very welcome.
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <h4 class="card-header">Current status</h4>
    <div class="card-body">
      <p>
        Image version: <b><?php echo $version?></b><br>
        Network mode: <b><?php echo $ethConnected ? 'Ethernet' : 'WiFi' ?></b><br>
        Network status: <b><?php echo $wlanConnected ?
                  ('Connected (' . trim($ssid) . ')')
                  : ($ethConnected ? 'Connected' : 'Not connected') ?></b> <br>
        PC network name: <b><?php echo isset($key) && trim($key) !== '' ? $key : 'mobro' ?></b>
      </p>
    </div>
  </div>

  <div class="card mt-3">
    <div class="card-header">
      <h4>Edit PC network name</h4>
    </div>
    <div class="card-body">
      <form action="saveKey.php" method="POST">
        <p>
          The 'PC network name' as configured in the settings of the MoBro PC application
        </p>
        <div class="form-group row mt-1">
          <div class="col-sm">
            <input id="idkey" type="text" name="key"
                   value="<?php echo isset($key) && trim($key) !== '' ? $key : 'mobro' ?>"
                   placeholder="Connection Key"
            class="form-control" required
            title="The 'PC network name' as configured in the MoBro PC application">
          </div>
          <div class="col-sm">
            <button class="btn btn-primary" type="submit">Apply</button>
          </div>
        </div>
      </form>
    </div>
  </div>


  <div class="card mt-3">
    <div class="card-header">
      <h4>Setup new WiFi connection</h4>
    </div>
    <div class="card-body">
      <div class="card-text">
        <p>
          In order to connect your Raspberry Pi to a (new) wireless network just follow these steps:
        </p>
        <ol>
          <li>
            Select the desired network from the drop down list<br/>
            (Or manually provide the SSID of the network in case your network is missing from the list)
          </li>
          <li>
            Provide the password for the selected wireless network
          </li>
          <li>
            Click on 'Connect'
          </li>
        </ol>
        <p>
          The Raspberry Pi will now try to connect to the given network using your provided credentials.<br/>
          If you were connected via the Raspberry's own hotspot, this network will be closed first and you will be
          disconnected.
        </p>
      </div>
      <form action="save.php" method="POST">
        <legend>Configuration:</legend>

        <div class="form-group row mt-1">
          <div class="col-sm">
            <label for="idssid">Network:</label>
            <select id="idssid" name="ssid" class="form-control" title="The wifi network to connect to">
                <?php
                if ($file = fopen(Constants::SSID_FILE, "r")) {
                    while (!feof($file)) {
                        $item = fgets($file);
                        if (trim($item) !== '') {
                            echo '<option>' . $item . '</option>';
                        }
                    }
                    fclose($file);
                }
                ?>
            </select>
          </div>
          <div class="col-sm">
            <label for="idmanualssid">Manuel network SSID: (overrides network selection)</label>
            <input id="idmanualssid" type="text" name="ssid_manual" placeholder="SSID (optional)" class="form-control"
                   title="Manual SSID override for the network selection">
          </div>
        </div>

        <div class="form-group row mt-1">
          <div class="col-sm">
            <label for="idpw">Password:</label>
            <input id="idpw" type="password" name="pw" placeholder="Password" class="form-control" required
                   title="The password for the selected wifi network">
          </div>
          <div class="col-sm">
          </div>
        </div>

        <p class="alert alert-info">
          Closing the hotspot and connecting to the new network might take some time, so be patient and give it a
          minute.<br/>
          In case of invalid credentials or any other connection error, the configuration hotspot will be recreated.
        </p>

        <button class="btn w-100 btn-primary" type="submit">Connect</button>
      </form>
    </div>
  </div>

  <?php include '../includes/footer.php' ?>

</div>

</body>
</html>