<?php

include '../../constants.php';

$cache_file = '/tmp/php_cache_perf';
$cache_seconds = 10;

$filter = "";
if (isset($_GET['filter'])) {
    $filter = strtolower($_GET['filter']);
}

$cache_file = $cache_file . $filter;
if (file_exists($cache_file) && (filemtime($cache_file) > (time() - $cache_seconds))) {
    header("Content-Type: application/json");
    echo file_get_contents($cache_file);
    return;
}

# not in cache, we need to read values
$arr = array(
    "ts" => time()
);
if (empty($filter) || strpos($filter, 'cpu') !== false) {
    $arr['cpu'] = json_decode(shell_exec(Constants::SCRIPT_CPU_STATS . " --json"));
}
if (empty($filter) || strpos($filter, 'memory') !== false) {
    $arr['memory'] =json_decode(shell_exec(Constants::SCRIPT_MEMORY_STATS . " --json"));
}
if (empty($filter)|| strpos($filter, 'filesystem') !== false) {
    $filesystems = array('root', 'home', 'boot');
    $fsArray = array();
    foreach ($filesystems as $fs) {
        $fsArray[$fs] = json_decode(shell_exec(Constants::SCRIPT_FILESYSTEM_STATS . " --json $fs"));
    }
    $arr['filesystem'] = $fsArray;
}

# put into cache before returning
$response = json_encode($arr);
file_put_contents($cache_file, $response, LOCK_EX);

header("Content-Type: application/json");
echo $response;
