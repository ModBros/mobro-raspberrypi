<?php

include '../../constants.php';

header("Content-Type: text/plain");

# return config file but remove PW line
$file = file_get_contents(Constants::FILE_MOBRO_CONFIG_READ);
$lines = explode("\n", $file);
$exclude = array();
foreach ($lines as $line) {
    if (strpos($line, 'network_pw') !== FALSE) {
        continue;
    }
    $exclude[] = $line;
}
echo implode("\n", $exclude);
