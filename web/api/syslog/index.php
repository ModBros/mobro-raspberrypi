<?php

include '../../constants.php';

header("Content-Type: text/plain");

$script = Constants::SCRIPT_SYSLOG;
if (isset($_GET['lines']) && is_numeric($_GET['lines'])) {
    echo shell_exec("sudo {$script} {$_GET['lines']}");
} else {
    echo shell_exec("sudo {$script}");
}
