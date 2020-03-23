<?php

$temp = shell_exec('sed "s/\(...\)$/.\1°C/" < /sys/class/thermal/thermal_zone0/temp');

header("Content-Type: text/plain");
echo $temp;
