<!--
Modbros Monitoring Service (MoBro) - Raspberry Pi image
Copyright (C) 2021 ModBros
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

function getPostValOrDefault($key, $default)
{
    return isset($_POST[$key]) ? $_POST[$key] : $default;
}

// localization
$localization_country = getPostValOrDefault('localization_country', 'AT');
$localization_timezone = getPostValOrDefault('localization_timezone', 'UTC');

// network
$network_mode = getPostValOrDefault('network_mode', 'wifi');
$network_ssid = getPostValOrDefault('network_ssid', '');
$network_pw = getPostValOrDefault('network_pw', '');
$network_wpa = getPostValOrDefault('network_wpa', '');
$network_hidden = empty($_POST['network_hidden']) ? '0' : '1';

// discovery
$discovery_mode = getPostValOrDefault('discovery_mode', 'auto');
$discovery_key = getPostValOrDefault('discovery_key', 'mobro');
$discovery_ip = getPostValOrDefault('discovery_ip', '');

// display
$display_driver = getPostValOrDefault('display_driver', '');
$display_hdmi_mode = getPostValOrDefault('display_hdmi_mode', '');
$display_rotation = getPostValOrDefault('display_rotation', '0');
$display_screensaver = getPostValOrDefault('display_screensaver', 'disabled');
$display_screensaver_url = getPostValOrDefault('display_screensaver_url', '');
$display_delay = getPostValOrDefault('display_delay', '5');

// advanced
$advanced_overclock_mode = getPostValOrDefault('advanced_overclock_mode', 'none');
$advanced_overclock_consent = empty($_POST['advanced_overclock_consent']) ? '0' : '1';
$advanced_configtxt = getPostValOrDefault('advanced_configtxt', '');
$advanced_configtxt = preg_replace('~\R~u', "\n", $advanced_configtxt);
$advanced_configtxt = $advanced_configtxt . "\n";
$advanced_fs_dis_overlayfs = empty($_POST['advanced_fs_dis_overlayfs']) ? '0' : '1';
$advanced_fs_persist_log = empty($_POST['advanced_fs_persist_log']) ? '0' : '1';

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
    "display_hdmi_mode={$display_hdmi_mode}\n" .
    "display_rotation={$display_rotation}\n" .
    "display_screensaver={$display_screensaver}\n" .
    "display_screensaver_url={$display_screensaver_url}\n" .
    "display_delay={$display_delay}\n" .
    "advanced_overclock_consent={$advanced_overclock_consent}\n" .
    "advanced_overclock_mode={$advanced_overclock_mode}\n" .
    "advanced_fs_dis_overlayfs={$advanced_fs_dis_overlayfs}\n" .
    "advanced_fs_persist_log={$advanced_fs_persist_log}\n";

file_put_contents(Constants::FILE_MOBRO_CONFIG_WRITE, $configuration_file_contents, LOCK_EX);
file_put_contents(Constants::FILE_MOBRO_CONFIGTXT_WRITE, $advanced_configtxt, LOCK_EX);

// apply config and reboot the Pi
shell_exec('sudo ' . Constants::SCRIPT_APPLY_CONFIG . ' "' . Constants::FILE_MOBRO_CONFIG_WRITE . '"  "' . Constants::FILE_MOBRO_CONFIGTXT_WRITE . '"');

