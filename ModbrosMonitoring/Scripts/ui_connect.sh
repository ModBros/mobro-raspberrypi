#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments supplied"
    exit 1
fi

./stopchrome.sh

./startchrome.sh 'http://localhost/modbros/connectwifi.php'

./connectwifi.sh $1 $2 $

sleep 10

exit 0
