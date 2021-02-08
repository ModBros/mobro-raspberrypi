#!/bin/bash

if [ $# -eq 0 ]; then
    sudo logread
else
    sudo logread | tail -n"$1"
fi
