<?php
include '../constants.php';

$lines = $_GET['lines'];
$all = isset($_GET['all']);

function getFile($lines, $file)
{
    if (isset($lines)) {
        return shell_exec("tail -n{$lines} {$file}");
    }
    return file_get_contents($file);
}

$base = Constants::LOG_DIR . '/log';
$log = getFile($lines, $base . '.txt');

if ($all) {
    for ($i = 0; $i < 10; $i++) {
        $path = $base . '_' . $i . '.txt';
        if (file_exists($path)) {
            $log .= "\n\n";
            $log .= "===========================================================================================\n";
            $log .= "========================================= LOG " . $i . " ============================================\n";
            $log .= "===========================================================================================\n";
            $log .= getFile($lines, $path);
        }
    }
}


header("Content-Type: text/plain");

echo $log;
