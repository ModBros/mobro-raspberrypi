<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
  <link href="./bootstrap.min.css" rel="stylesheet"/>
</head>
<style>
  body {
    font-size: 20px;
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
          $ssid = shell_exec('cat /home/pi/ModbrosMonitoring/data/wifi.txt | sed -n 1p');
          if (isset($ssid) && trim($ssid) !== '') {
              echo 'Now trying to connect to: <br/><b>' . $ssid . '</b>';
          } else {
              echo '<b>Error while trying to connect!</b>';
          }
          ?>
      </p>
      <p>
        Note: After a successful connection your Pi will perform a quick reboot.<br>
        This is intended and normal.
      </p>
    </div>
  </div>
</div>

</body>
</html>