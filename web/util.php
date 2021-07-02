<?php

function getIfNotEof($file, $default): string
{
    return $file && !feof($file) ? trim(fgets($file)) : $default;
}

function closeFile($file)
{
    if ($file) {
        fclose($file);
    }
}

function getFirstLine($filePath, $default): string
{
    $file = fopen($filePath, "r");
    $line = getIfNotEof($file, $default);
    closeFile($file);
    return $line;
}

function getOrDefault($var, $default): string
{
    return trim(!empty($var) || $var == "0" ? $var : $default);
}

function parseProperties($filePath): array
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

function getDriverScripts($dir, $prefix): array
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

function getGroupedTimeZones(): array
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

function getGoodTFTDrivers(): array
{
    return getDriverScripts(Constants::DIR_DRIVER_GOODTFT, null);
}

function getWaveshareDrivers(): array
{
    return getDriverScripts(Constants::DIR_DRIVER_WAVESHARE, null);
}

function getOfficialRaspberryPiDrivers(): array
{
    return [
        'pi7' => 'Official 7" touchscreen display'
    ];
}

function getOtherDriverOptions(): array
{
    return [
        'default' => 'Default (HDMI, flat ribbon cable, ...)',
    ];
}

function getAllDrivers(): array
{
    return array_merge(
        getOtherDriverOptions(),
        getOfficialRaspberryPiDrivers(),
        getDriverScripts(Constants::DIR_DRIVER_GOODTFT, 'GoodTFT'),
        getDriverScripts(Constants::DIR_DRIVER_WAVESHARE, 'WaveShare')
    );
}

function getDefaultScreensaverOptions(): array
{
    return [
        'disabled' => 'Disabled',
        'black.html' => 'Black',
    ];
}

function getClockScreensavers(): array
{
    return [
        'clock_date.php' => 'Date + Time',
        'pong.php' => 'Pong',
        'particle_clock.php' => 'Particle Clock (animated)',
        'snow_clock.php' => 'Snow Clock (animated)',
    ];
}

function getMiscScreensavers(): array
{
    return [
        'particle.html' => 'Particles (animated)',
        'snow.html' => 'Snow (animated)',
        'njancat.html' => 'Njancat (animated)',
        'mobro_boot_light.html' => 'MoBro Boot screen (light)',
        'mobro_boot_dark.html' => 'MoBro Boot screen (dark)',
        'mobro_logo_dark.html' => 'MoBro Logo',
        'mobro_logo_dark_bounce.html' => 'MoBro Logo (animated)',
        'modbros_logo_dark.html' => 'ModBros Logo',
        'modbros_logo_dark_bounce.html' => 'ModBros Logo (animated)'
    ];
}

function getOnlineScreensavers(): array
{
    return [
        'custom' => 'Custom URL',
        'unsplash.html' => 'Random Unsplash images',
        'https://www.windy.com' => 'Windy',
        'https://www.flightradar24.com' => 'Flightradar',
        'https://www.marinetraffic.com' => 'Marinetraffic'
    ];
}

function getAllScreensavers(): array
{
    return array_merge(
        getDefaultScreensaverOptions(),
        getClockScreensavers(),
        getOnlineScreensavers(),
        getMiscScreensavers()
    );
}

function getOverClocks(): array
{
    if (isPiZero()) {
        return array(
            'none' => 'None',
            'high' => 'High: 1050MHz ARM, 450MHz core, 450MHz SDRAM, 6 overvolt',
            'turbo' => 'Turbo: 1100MHz ARM, 500MHz core, 500MHz SDRAM, 6 overvolt'
        );
    }
    if (isPiOne()) {
        return array(
            'none' => 'None',
            'modest' => 'Modest: 800MHz ARM, 250MHz core, 400MHz SDRAM, 0 overvolt',
            'medium' => 'Medium: 900MHz ARM, 250MHz core, 450MHz SDRAM, 2 overvolt',
            'high' => 'High: 950MHz ARM, 250MHz core, 450MHz SDRAM, 6 overvolt',
            'turbo' => 'Turbo: 1000MHz ARM, 500MHz core, 600MHz SDRAM, 6 overvolt'
        );
    }
    if (isPiTwo()) {
        return array(
            'none' => 'None',
            'high' => 'High: 1000MHz ARM, 500MHz core, 500MHz SDRAM, 2 overvolt',
        );
    }
    return array(
        'none' => 'Unavailable'
    );
}

function isPiZero(): bool
{
    return shell_exec('grep -c "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo') > 0;
}

function isPiOne(): bool
{
    $isPiOne = shell_exec('grep -c "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo') > 0;
    $isPiOne |= shell_exec('grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo') > 0;
    return $isPiOne;
}

function isPiTwo(): bool
{
    return shell_exec('grep -c "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo') > 0;
}

function overclockSupported(): bool
{
    return isPiZero() || isPiOne() || isPiTwo();
}
