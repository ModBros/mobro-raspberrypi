<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
  <link href="../bootstrap.min.css" rel="stylesheet"/>
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
              echo 'Currently connected to: <b>' . $ssid . '</b>';
          } else {
              echo '<b>Currently not connected!</b>';
          }
          ?>
      </p>
      <p>
          <?php
          $key = shell_exec('cat /home/modbros/ModbrosMonitoring/data/wifi.txt | sed -n 3p');
          if (isset($key) && trim($key) !== '') {
              echo 'Now searching your network for the ModBros Monitoring application on your PC using key <b>' . $key . '</b>';
          } else {
              echo 'Now searching your network for the running ModBros Monitoring application on your PC...';
          }
          ?>
      </p>
      <p>
        This might take some time.<br>
      </p>
    </div>
  </div>
</div>

</body>
</html>