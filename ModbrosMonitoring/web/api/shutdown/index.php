<?php

header("Content-Type: text/plain");
$delay = $_GET['delay'];
if (isset($delay) && is_numeric($delay)) {
    shell_exec("sudo /sbin/shutdown -h +{$delay}");
} else {
    shell_exec('sudo /sbin/shutdown -h now');
}
