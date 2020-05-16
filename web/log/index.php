<?php
include '../constants.php';

function getFile($file)
{
    if (isset($_GET['lines'])) {
        return shell_exec("tail -n{$_GET['lines']} {$file}");
    }
    return file_get_contents($file);
}

$count = $_GET['count'] ?: 0;
$count = min($count, 10);

$base = Constants::DIR_LOG . '/log';
$log = getFile($base . '.txt');

for ($i = 0; $i < $count; $i++) {
    $path = $base . '_' . $i . '.txt';
    if (file_exists($path)) {
        $log .= "\n\n";
        $log .= "===========================================================================================\n";
        $log .= "|                                         LOG {$i}                                           |\n";
        $log .= "===========================================================================================\n";
        $log .= getFile($path);
    }
}

header("Content-Type: text/plain");

echo $log;
