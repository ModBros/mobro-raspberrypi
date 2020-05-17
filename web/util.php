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
