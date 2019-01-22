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
  <h1>ModBros Monitoring Setup</h1>
  <p>
    Hi there!
  </p>
  <p>
    You are seeing this configuration page, which means your setup of the ModBros Monitoring Tool is almost complete.
  </p>
  <p>
    Soon you will have your very own MoBro. (<b>Mo</b>nitoring<b>Bro</b> - get it &#128521;)
  </p>
  <p>
    Thanks again for giving our software a shot!<br/>
    As this is our first adventure into the PC stats monitoring territory, both your honest feedback as well as
    suggestions for future improvements would be very welcome.
  </p>

  <hr/>

  <h3>Current connection</h3>
  <p>
      <?php
      $ssid = shell_exec('iwgetid wlan0 -r');
      if (isset($ssid) && trim($ssid) !== '') {
          echo 'You are currently connected to: ' . $ssid;
      } else {
          echo 'Currently not connected!';
      }
      ?>
  </p>

  <hr/>

  <h3>Setup new connection</h3>
  <p>
    In order to connect your Raspberry Pi to a (new) wireless network just do the follow:
  </p>
  <ol>
    <li>
      Select the desired network from the drop down list.<br/>
      (Or provide the SSID of the network in case the Raspberry was unable to identify available networks and no drop
      down is shown)
    </li>
    <li>
      Provide the password for the selected wireless network.<br/>
      (Make sure Caps Lock is disabled)
    </li>
    <li>
      Click on 'Connect'
    </li>
  </ol>
  <p>
    Your Raspberry Pi will now try to connect to the given network using your provided credentials.<br/>
    If you were connected via the Raspberry's own hotspot, this network will be closed first and you will be
    disconnected.
  </p>

  <form action="save.php" method="POST">
    <fieldset>
      <legend>Wireless Lan Information:</legend>
        <?php
        if ($file = fopen("networks", "r")) {
            echo 'Network:<br>';
            echo '<select name="ssid">';
            while (!feof($file)) {
                $item = fgets($file);
                if (trim($item) !== '') {
                    echo '<option>' . $item . '</option>';
                }
            }
            echo '</select>';
            fclose($file);
        } else {
            echo 'SSID:<br>';
            echo '<input type="text" name="ssid" value="">';
        }
        ?>
      <br/>

      Password:<br>
      <input type="password" name="pw" value="">
      <br/><br/>

      <input type="submit" value="Connect" onclick="return confirm('Connect to the given network?')">

    </fieldset>
  </form>

  <p>
    Note that closing the hotspot and connecting to the new network might take some time, so be patient.<br/>
    In case of invalid credentials or any other connection error, the configuration hotspot will be recreated.
  </p>

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