<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
  <link href="./bootstrap.min.css" rel="stylesheet"/>
</head>
<style>
  body {
    font-size: 16px;
  }
</style>
<body>

<div id="container" class="container">
  <div class="card mt-3">
    <div class="card-header">
      <h3 class="m-0">ModBros Monitoring Setup</h3>
    </div>

    <div class="card-body">
      <p>
          <?php
          $ssid = shell_exec('iwgetid wlan0 -r');
          if (isset($ssid) && trim($ssid) !== '') {
              echo 'Your Raspberry is currently connected to: <b>' . $ssid . '</b>';
          } else {
              echo '<b>Currently not connected!</b>';
          }
          ?>
      </p>
      <p>
        Now searching your network for the running ModBros Monitoring application on your PC...
      </p>
      <p>
        This might take some time.<br>
        Once the application is located, your monitoring data will appear right here on this screen :)
      </p>
    </div>
  </div>
</div>

</body>
</html>