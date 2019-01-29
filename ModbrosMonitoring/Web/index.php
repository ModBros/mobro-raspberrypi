<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ModBros Monitoring Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
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
				Hi there!
			  </p>
			  <p>
				You are seeing this configuration page, which means your setup of the ModBros Monitoring Tool is almost complete.
			  </p>
			  <p>
				Soon you will have your very own MoBro. (<b>Mo</b>nitoring<b>Bro</b> - get it &#128521;)
			  </p>
			  <p class="m-0">
				Thanks again for giving our software a shot!<br/>
				As this is our first adventure into the PC stats monitoring territory, both your honest feedback as well as
				suggestions for future improvements would be very welcome.
			  </p>
		</div>
	</div>

	
	<div class="card mt-3">
		<div class="card-header">
			<h3 class="m-0">Current connection</h3>
		</div>
		
		<div class="card-body">
			<p class="m-0">
			  <?php
			  $ssid = shell_exec('iwgetid wlan0 -r');
			  if (isset($ssid) && trim($ssid) !== '') {
				  echo 'You are currently connected to: ' . $ssid;
			  } else {
				  echo 'Currently not connected!';
			  }
			  ?>
			</p>
		</div>
	</div>

	<div class="card mt-3">
		<div class="card-header">
			<h3 class="m-0">Setup new connection</h3>
		</div>
		
		<div class="card-body">
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
				  Provide the password for the selected wireless network.
				</li>
				<li>
				  Provide the individual connection key as given to you by the desktop application.
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
						echo '<label>Network:</label><br>';
						echo '<select name="ssid" class="form-control">';
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

				  <label class="mt-2">Password:</label><br>
				  <input type="password" name="pw" value="" class="form-control">
				  
				  <label class="mt-2">Key:</label><br>
				  <input type="text" name="key" value="mobro" class="form-control">
				  
				  <input type="submit" value="Connect" class="btn btn-primary w-100 mt-3" onclick="return confirm('Connect to the given network?')">

				</fieldset>
			  </form>
		</div>
	</div>

  <div class="alert alert-info mt-3">
    Note that closing the hotspot and connecting to the new network might take some time, so be patient.<br/>
    In case of invalid credentials or any other connection error, the configuration hotspot will be recreated.
  </div>

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