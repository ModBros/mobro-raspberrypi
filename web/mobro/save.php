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

// localization
$localization_country = getOrDefault('localization_country', 'AT');
$localization_timezone = getOrDefault('localization_timezone', 'UTC');

// network
$network_mode = getOrDefault('network_mode', 'wifi');
$network_ssid = getOrDefault('network_ssid', '');
$network_pw = getOrDefault('network_pw', '');
$network_wpa = getOrDefault('network_wpa', '');
$network_hidden = empty($_POST['network_hidden']) ? '0' : '1';

// discovery
$discovery_mode = getOrDefault('discovery_mode', 'auto');
$discovery_key = getOrDefault('discovery_key', 'mobro');
$discovery_ip = getOrDefault('discovery_ip', '');

// display
$display_driver = getOrDefault('display_driver', '');
$display_rotation = getOrDefault('display_rotation', '0');
$display_screensaver = getOrDefault('display_screensaver', 'disabled');
$display_screensaver_delay = getOrDefault('display_screensaver_delay', '1');

// write configuration file
$configuration_file_contents =
    "localization_country={$localization_country}\n" .
    "localization_timezone={$localization_timezone}\n" .
    "network_mode={$network_mode}\n" .
    "network_ssid={$network_ssid}\n" .
    "network_pw={$network_pw}\n" .
    "network_wpa={$network_wpa}\n" .
    "network_hidden={$network_hidden}\n" .
    "discovery_mode={$discovery_mode}\n" .
    "discovery_key={$discovery_key}\n" .
    "discovery_ip={$discovery_ip}\n" .
    "display_driver={$display_driver}\n" .
    "display_rotation={$display_rotation}\n" .
    "display_screensaver={$display_screensaver}\n" .
    "display_screensaver_delay={$display_screensaver_delay}\n";
file_put_contents(Constants::FILE_MOBRO_CONFIG, $configuration_file_contents, LOCK_EX);


// apply config and reboot the Pi
shell_exec('sudo ' . Constants::SCRIPT_APPLY_CONFIG);
