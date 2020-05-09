<?php

include '../../constants.php';

header("Content-Type: text/plain");
$delay = $_GET['delay'];
$script = Constants::SCRIPT_SHUTDOWN;
if (isset($delay) && is_numeric($delay)) {
    shell_exec("sudo {$script} -h +{$delay}");
} else {
    shell_exec("sudo {$script} -h now");
}
