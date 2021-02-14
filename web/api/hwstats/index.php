<?php

include '../../constants.php';

$cache_file = '/tmp/php_cache_perf';
$cache_seconds = 10;

$categories = 'cpu,memory';
if (isset($_GET['categories'])) {
    $categories = strtolower($_GET['categories']);
}

$cache_file = $cache_file . $categories;
if (file_exists($cache_file) && (filemtime($cache_file) > (time() - $cache_seconds))) {
    header("Content-Type: application/json");
    echo file_get_contents($cache_file);
    return;
}

# not in cache, we need to read values
$arr = array(
    "ts" => time()
);
if (strpos($categories, 'cpu') !== false) {
    $arr['cpu'] = array(
        "cores" => intval(shell_exec(Constants::SCRIPT_CPU_STATS . ' --processors')),
        "temperature" => floatval(shell_exec(Constants::SCRIPT_CPU_STATS . ' --temperature')),
        "usage" => floatval(shell_exec(Constants::SCRIPT_CPU_STATS . ' --load')),
        "clock" => intval(shell_exec(Constants::SCRIPT_CPU_STATS . ' --clock'))
    );
}
if (strpos($categories, 'memory') !== false) {
    $arr['memory'] = array(
        "total" => floatval(shell_exec(Constants::SCRIPT_MEMORY_STATS . ' --total')),
        "used" => floatval(shell_exec(Constants::SCRIPT_MEMORY_STATS . ' --used')),
        "free" => floatval(shell_exec(Constants::SCRIPT_MEMORY_STATS . ' --free')),
        "usage" => floatval(shell_exec(Constants::SCRIPT_MEMORY_STATS . ' --load'))
    );
}
if (strpos($categories, 'filesystem') !== false) {
    $filesystems = array('root', 'home', 'boot');
    $fsArray = array();
    foreach ($filesystems as $fs) {
        $fsArray[$fs] = array(
            "status" => shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --status $fs"),
            "mounted" => shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --mount $fs"),
            "filesystem" => shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --filesystem $fs"),
            "used" => floatval(shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --used $fs")),
            "free" => floatval(shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --available $fs")),
            "usage" => floatval(shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --load $fs"))
        );
    }
    $arr['filesystem'] = $fsArray;
}

# put into cache before returning
$response = json_encode($arr);
file_put_contents($cache_file, $response, LOCK_EX);

header("Content-Type: application/json");
echo $response;
