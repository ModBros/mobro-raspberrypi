<?php

function getIfNotEof($file, $default)
{
    return $file && !feof($file) ? trim(fgets($file)) : $default;
}

function closeFile($file)
{
    if ($file) {
        fclose($file);
    }
}

function getFirstLine($filePath, $default)
{
    $file = fopen($filePath, "r");
    $line = getIfNotEof($file, $default);
    closeFile($file);
    return $line;
}

function getOrDefault(&$var, $default)
{
    return trim($var ?: $default);
}

function parseProperties($filePath)
{
    $fileContent = file_get_contents($filePath);
    $result = [];
    $fileContent = str_replace("\r\n", "\n", $fileContent);
    $lines = explode("\n", $fileContent);
    $lastkey = '';
    $appendNextLine = false;
    foreach ($lines as $l) {
        $cleanLine = trim($l);
        if ($cleanLine === '') continue;
        if (strpos($cleanLine, '#') === 0) {
            continue; // is comment ... move on
        }
        $endsWithSlash = substr($l, -1) === '\\';
        if ($appendNextLine) {
            $result[$lastkey] .= "\n" . substr($l, 0, $endsWithSlash ? -1 : 10000);
            if (!$endsWithSlash) { // last line of multi-line property does not end with '\' char
                $appendNextLine = false;
            }
        } else {
            $key = trim(substr($l, 0, strpos($l, '=')));
            $value = substr($l, strpos($l, '=') + 1, $endsWithSlash ? -1 : 10000);
            $lastkey = $key;
            $result[$key] = $value;
            $appendNextLine = $endsWithSlash;
        }
    }
    return $result;
}

function getDriverScripts($dir, $prefix)
{
    $result = array();
    foreach (scandir($dir) as $key => $value) {
        $full_path = $dir . DIRECTORY_SEPARATOR . $value;
        if (!is_dir($full_path)) {
            if (fnmatch('*show', $value)) {
                if (isset($prefix)) {
                    $result[$full_path] = $prefix . " - " . $value;
                } else {
                    $result[$full_path] = $value;
                }
            }
        }
    }
    return $result;
}

function getGroupedTimeZones()
{
    $result = array();
    if (($handle = fopen(Constants::FILE_TIMEZONES, "r")) !== FALSE) {
        while (($data = fgetcsv($handle, 1000, "/")) !== FALSE) {
            if (!array_key_exists($data[0], $result)) {
                $result[$data[0]] = array();
            }
            $result[$data[0]][implode("/", $data)] = end($data);
        }
        fclose($handle);
    }
    return $result;
}

function getGoodTFTDrivers()
{
    return getDriverScripts(Constants::DIR_DRIVER_GOODTFT, null);
}

function getWaveshareDrivers()
{
    return getDriverScripts(Constants::DIR_DRIVER_WAVESHARE, null);
}

function getOtherDriverOptions()
{
    return [
        'hdmi' => 'HDMI',
        'manual' => 'Manual installation'
    ];
}

function getAllDrivers()
{
    return array_merge(
        getOtherDriverOptions(),
        getDriverScripts(Constants::DIR_DRIVER_GOODTFT, 'GoodTFT'),
        getDriverScripts(Constants::DIR_DRIVER_WAVESHARE, 'WaveShare')
    );
}

function getScreensavers()
{
    return [
        'disabled' => 'Disabled',
        'black.html' => 'Black',
        'mobro_boot_light.html' => 'MoBro - Boot screen',
        'mobro_boot_dark.html' => 'MoBro - Boot screen (dark)',
        'mobro_logo_dark.html' => 'MoBro - Logo',
        'mobro_logo_dark_bounce.html' => 'MoBro - Logo (bounce)',
        'modbros_logo_dark.html' => 'ModBros - Logo',
        'modbros_logo_dark_bounce.html' => 'ModBros - Logo (bounce)',
        'clock_date.php' => 'Date + Clock',
        'pong.php' => 'Pong Clock'
    ];
}
