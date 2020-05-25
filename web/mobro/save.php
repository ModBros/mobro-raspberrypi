<!--
Modbros Monitoring Service (MoBro) - Raspberry Pi image
Copyright (C) 2020 ModBros
Contact: mod-bros.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

<?php

include '../constants.php';

// debug
//echo '<table>';
//foreach ($_POST as $key => $value) {
//    echo "<tr>";
//    echo "<td>" . $key . "</td>";
//    echo "<td>" . $value . "</td>";
//    echo "</tr>";
//}
//echo '</table>';
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

// write network file if in wifi mode
if ($netMode == 'wifi') {
    $wifiData =
        "mode={$netMode}\n" .
        "ssid={$ssid}\n" .
        "pw={$pw}\n" .
        "country={$country}\n" .
        "hidden={$hidden}\n" .
        "wpa={$wpa}\n";
    file_put_contents(Constants::FILE_WIFI, $wifiData, LOCK_EX);
}

// write discovery file
$discoveryData =
    "mode={$pcMode}\n" .
    "key={$connKey}\n" .
    "ip={$ip}\n";
file_put_contents(Constants::FILE_DISCOVERY, $discoveryData, LOCK_EX);

// write driver file if selected
if ($screenMode == 'install' && !empty($driver)) {
    file_put_contents(Constants::FILE_DRIVER, $driver, LOCK_EX);
}

// apply config and reboot the Pi
shell_exec('sudo ' . Constants::SCRIPT_APPLY_CONFIG);