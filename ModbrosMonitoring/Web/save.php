<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
</head>
<body>

<div id="container">

  <h2>ModBros Monitoring</h2>
  <p>
    You Raspberry Pi will now close this access point and start trying to connect to:
  </p>
  <p>
      <?php
      $ssid = $_POST['ssid'];
      echo '<b>' . $ssid . '</b>';
      ?>
  </p>
  <p>
    This might take some time.<br>
    Once connected, it will try and locate your instance of the ModBros Monitoring application using the provided
    connection key:
  </p>
  <p>
      <?php
      $key = $_POST['key'];
      echo '<b>' . $key . '</b>';
      ?>
  </p>

  <hr/>

  <h5>Script output:</h5>
  <pre>
    <?php
    if (isset($_POST['ssid']) && isset($_POST['pw']) && isset($_POST['key'])) {
        $ssid = $_POST['ssid'];
        $pw = $_POST['pw'];
        $key = $_POST['key'];
        $data = 'SSID: ' . $ssid . "\nPW: " . $pw . "\nKEY: " . $key . "\n";
        $ret = file_put_contents('/home/pi/ModbrosMonitoring/wlan_access_data.txt', $data, LOCK_EX);
        if ($ret === false) {
            echo('There was an error saving the access data!');
        } else {
            echo "wifi access data successfully saved \n($ret bytes written)\n";
            echo "trying to connect to network '" . $ssid . "' using the provided password...\n";
            $response = shell_exec('cd /home/pi/ModbrosMonitoring && sudo /home/pi/ModbrosMonitoring/connectwifi.sh ' . $ssid . ' ' . $pw . ' 2>&1');
            echo "\n" . $response;
        }
    } else {
        echo('Error! Missing data!');
    }
    ?>
  </pre>
  <br/>
  <a href="index.php" class="previous">&laquo; Back</a>
  <br/>

  <hr/>

  <footer>
    <p>
      Created with &#9829; in Austria by: &#169; ModBros 2019<br/>
      Contact: <a href="https://mod-bros.com">mod-bros.com</a><br/>
    </p>
  </footer>
</div>

</body>
</html>