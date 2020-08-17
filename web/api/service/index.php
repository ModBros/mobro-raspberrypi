<?php

include '../../constants.php';

header("Content-Type: text/plain");
$action = $_GET['action'];
$script = Constants::SCRIPT_SERVICE;
if (!isset($action)) {
    $action = "restart";
}
shell_exec("sudo {$script} {$action}");
