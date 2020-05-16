<?php
include '../constants.php';

$all = isset($_GET['all']);

function getFile($file)
{
    if (isset($_GET['lines'])) {
        $lines = $_GET['lines'];
        return shell_exec("tail -n{$lines} {$file}");
    }
    return file_get_contents($file);
}

$base = Constants::DIR_LOG . '/log';
$log = getFile($base . '.txt');

if ($all) {
    for ($i = 0; $i < 10; $i++) {
        $path = $base . '_' . $i . '.txt';
        if (file_exists($path)) {
            $log .= "\n\n";
            $log .= "===========================================================================================\n";
            $log .= "|                                         LOG {$i}                                           |\n";
            $log .= "===========================================================================================\n";
            $log .= getFile($path);
        }
    }
}


header("Content-Type: text/plain");

echo $log;
