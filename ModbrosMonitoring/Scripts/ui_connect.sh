#!/usr/bin/env bash

sudo ./stopchrome.sh

sleep 2

DISPLAY=:0 ./startchrome.sh 'http://localhost/modbros/connectwifi.php' &

sleep 10

exit 0
