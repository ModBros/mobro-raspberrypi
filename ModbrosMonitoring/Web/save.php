<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
</head>
<body>

<div id="container">

  <pre>
    <?php
    if (isset($_POST['ssid']) && isset($_POST['pw'])) {
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
            $response = shell_exec(dirname(__FILE__) . '/scripts/connectwifi.sh ' . $ssid . ' ' . $pw . ' 2>&1');
            echo "\n" . $response;
        }
    } else {
        echo('no post data to process');
    }
    ?>
  </pre>
  <br/>
  <a href="index.php" class="previous">&laquo; Back</a>

</div>

</body>
</html>