<?php
include '../../constants.php';

header("Content-Type: text/plain");

$logfile = Constants::FILE_LOG;
if (isset($_GET['lines']) && is_numeric($_GET['lines'])) {
    echo shell_exec("tail -n{$_GET['lines']} {$logfile}");
} else {
    echo file_get_contents($logfile);
}
