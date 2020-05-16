<?php

$top = shell_exec('top -b -n 1');

header("Content-Type: text/plain");
echo $top;
