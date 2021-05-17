#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [OPTION] [WIFI-INTERFACE]
  options:
   -h,  --help           this message
   -s,  --ssid           SSID
   -fr, --frequency      wifi frequency
   -ap, --access-point   access point mac address
   -br, --bitrate        bitrate
   -tp, --tx-power       tx-power
   -lq, --quality        link quality
   -sl, --signal         signal level
   -j,  --json           all values in json format
TEXT
}

get_ssid() {
  echo "$1" | grep "ESSID" | sed -e 's/^.*ESSID:"\([^ ]*\)".*$/\1/'
}

get_frequency() {
  echo "$1" | grep "Frequency" | sed -e 's/^.*Frequency:\([^ ]* [^ ]*\) .*$/\1/'
}

get_access_point() {
  echo "$1" | grep "Access Point" | sed -n -e 's/^.*Access Point: //p' | awk '{$1=$1};1'
}

get_bit_rate() {
  echo "$1" | grep "Bit Rate" | sed -e 's/^.*Bit Rate=\([^ ]* [^ ]*\) .*$/\1/'
}

get_tx_power() {
  echo "$1" | grep "Tx-Power" | sed -n -e 's/^.*Tx-Power=//p' | awk '{$1=$1};1'
}

get_link_quality() {
  echo "$1" | grep "Link Quality" | sed -e 's/^.*Link Quality=\([^ ]*\) .*$/\1/'
}

get_signal_level() {
  echo "$1" | grep "Signal level" | sed -n -e 's/^.*Signal level=//p' | awk '{$1=$1};1'
}

[ "$#" != 2 -o "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

case "$1" in
-s | --ssid)
  get_ssid "$(iwconfig "$2")"
  ;;
-fr | --frequency)
  get_frequency "$(iwconfig "$2")"
  ;;
-ap | --access-point)
  get_access_point "$(iwconfig "$2")"
  ;;
-br | --bitrate)
  get_bit_rate "$(iwconfig "$2")"
  ;;
-tp | --tx-power)
  get_tx_power "$(iwconfig "$2")"
  ;;
-lq | --quality)
  get_link_quality "$(iwconfig "$2")"
  ;;
-sl | --signal)
  get_signal_level "$(iwconfig "$2")"
  ;;
-j | --json)
  IWCONFIG=$(iwconfig "$2")
  printf '{"ssid":"%s","frequency":"%s","accessPoint":"%s","bitrate":"%s","txPower":"%s","linkQuality":"%s","signalLevel":"%s"}\n' \
    "$(get_ssid "$IWCONFIG")" \
    "$(get_frequency "$IWCONFIG")" \
    "$(get_access_point "$IWCONFIG")" \
    "$(get_bit_rate "$IWCONFIG")" \
    "$(get_tx_power "$IWCONFIG")" \
    "$(get_link_quality "$IWCONFIG")" \
    "$(get_signal_level "$IWCONFIG")"
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
