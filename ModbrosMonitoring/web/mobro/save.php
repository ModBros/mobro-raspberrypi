<?php

include '../constants.php';

// debug
echo '<table>';
foreach ($_POST as $key => $value) {
    echo "<tr>";
    echo "<td>" . $key . "</td>";
    echo "<td>" . $value . "</td>";
    echo "</tr>";
}
echo '</table>';

//exit();

function getOrDefault($key, $default)
{
    return isset($_POST[$key]) ? $_POST[$key] : $default;
}

// network
$netMode = getOrDefault('networkMode', 'wifi');
$ssid = getOrDefault('ssid', '');
$pw = getOrDefault('pw', '');
$country = getOrDefault('country', 'AT');
$wpa = getOrDefault('wpa', '');
$hidden = empty($_POST['hidden']) ? '0' : '1';

// pc
$pcMode = getOrDefault('discovery', 'auto');
$connKey = getOrDefault('key', 'mobro');
$ip = getOrDefault('ip', '');

// screen
$screenMode = getOrDefault('screen', 'hdmi');
$driver = getOrDefault('driver', '');

$time = time();

// write network file if in wifi mode
if ($netMode == 'wifi') {
    $wifiData = $netMode . "\n" . $ssid . "\n" . $pw . "\n" . $country . "\n" . $hidden . "\n" . $wpa . "\n" . $time . "\n";
    file_put_contents(Constants::FILE_WIFI, $wifiData, LOCK_EX);
}

// write discovery file
$discoveryData = $pcMode . "\n" . $connKey . "\n" . $ip . "\n" . $time . "\n";
file_put_contents(Constants::FILE_DISCOVERY, $discoveryData, LOCK_EX);

// write driver file if selected
if ($screenMode == 'install' && !empty($driver)) {
    file_put_contents(Constants::FILE_DRIVER, $driver, LOCK_EX);
}

// apply config and reboot the Pi
shell_exec('sudo .' . Constants::SCRIPT_APPLY_CONFIG);
