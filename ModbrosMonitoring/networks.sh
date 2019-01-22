#!/usr/bin/env bash

iwlist wlan0 scan | grep -i essid: | sed 's/^.*"\(.*\)"$/\1/'
