<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>MoBro Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <link rel="shortcut icon" href="favicon.ico" type="image/x-icon"/>
  <link href="../bootstrap.min.css" rel="stylesheet"/>
  <link href="../bootstrap.min.js" rel="script">
</head>

<body>
<?php

include '../constants.php';

if ($file = fopen(Constants::KEY_FILE, "r")) {
    if (!feof($file)) {
        $key = fgets($file);
    }
    fclose($file);
}
?>

<div id="container" class="container">

    <?php include 'header.php' ?>

  <div class="card mt-3">
    <div class="card-header">
      <h4>New connection setup</h4>
    </div>
    <div class="card-body">
      <div class="card-text">
        <p>
          Provided configuration values:
        </p>
        <p>
          Network SSID: <?php echo '<b>' . $_POST['ssid'] . '</b>'; ?> <br>
          Password: <?php echo '<b>' . str_repeat("*", strlen($_POST['pw'])) . '</b>' ?>
        </p>
        <p>
          PC network name: <?php echo '<b>' . $key . '</b>'; ?> <br>
        </p>
        <hr>
        <p>
          The Raspberry Pi will now close this access point and start trying to connect to the configured wireless
          network<br>
          This might take some time, so please be patient and give it a minute.<br>
        </p>
        <p>
          If the connection succeeds, it will continue and try to locate the PC running the MoBro desktop application
          using the configured PC network name.<br>
          Should the connection attempt fail, the configuration hotspot will be re-created.
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <div class="card-header">
      <h5>Troubleshooting</h5>
    </div>
    <div class="card-body">
      <div class="card-text">
        <p>
          In case the connection attempt fails, please make sure:
        </p>
        <ul>
          <li>
            You selected the correct WiFi network<br>
            (In case your WiFi network is not listed or the Raspberry fails to detect any networks, you can try to
            manually override the selection by providing your networks SSID)
          </li>
          <li>
            The provided password is correct<br>
          </li>
          <li>
            The Raspberry Pi is in range of your Wifi network
          </li>
        </ul>
        <p>
          In case the Raspberry is able to connect to your network, but fails to locate your PC:
        <ul>
          <li>
            Make sure the configured PC network name matches the one configured in the MoBro PC application<br>
            (check for upper/lower case)
          </li>
        </ul>
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <div class="card-header">
      <h5>Log output</h5>
    </div>

    <div class="card-body">
      <pre>
          <?php
          if (isset($_POST['pw']) && (isset($_POST['ssid']) || isset($_POST['ssid_manual']))) {
              $ssid = (empty($_POST['ssid_manual']) ? $_POST['ssid'] : $_POST['ssid_manual']);
              $pw = $_POST['pw'];
              $updated = time();
              $data = $ssid . "\n" . $pw . "\n" . $updated . "\n";
              $ret = false;
              $ret = file_put_contents(Constants::WIFI_FILE, $data, LOCK_EX);

              if ($ret === false) {
                  echo('There was an error saving the access data!');
              } else {
                  echo "wifi access data successfully saved \n($ret bytes written)\n";
                  echo "trying to connect to network '" . $ssid . "' using the provided password...\n";
              }
          } else {
              echo('Error! Missing data!');
          }
          ?>
      </pre>
    </div>
  </div>


  <a href="index.php" class="previous btn btn-primary mt-3">&laquo; Back</a>

  <hr>

    <?php include 'footer.php' ?>

</div>

</body>
</html>