<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
</head>
<style>
  body {
    font-size: 16px;
  }
</style>
<body>

<div id="container">
  <h2>ModBros Monitoring</h2>
  <p>
    Your Raspberry is currently connected to the following network:
  </p>
  <p>
      <?php
      $ssid = shell_exec('iwgetid wlan0 -r');
      if (isset($ssid) && trim($ssid) !== '') {
          echo '<b>' . $ssid . '</b>';
      } else {
          echo '<b>Currently not connected!</b>';
      }
      ?>
  </p>
  <hr/>
  <p>
    Now searching your network for the running ModBros Monitoring application on your PC...
  </p>
  <p>
    This might take some time.<br>
    Once the application is located, your monitoring data will appear right here on this screen :)
  </p>
</div>

</body>
</html>