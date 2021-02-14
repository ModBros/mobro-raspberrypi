#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [-h|-l|-t|-u|-f]
   -h, --help     This message
   -l, --load     Memory usage in %
   -t, --total    Total memory in MB
   -u, --used     Used memory in MB
   -f, --free     Free memory in MB
TEXT
}

[ "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

case "$1" in
--load | -l)
  free | awk 'NR == 2 {printf "%.2f", ($3/$2*100)}'
  ;;
--total | -t)
  free | awk 'NR == 2 {printf "%.2f", ($2/1024)}'
  ;;
--used | -u)
  free | awk 'NR == 2 {printf "%.2f", ($3/1024)}'
  ;;
--free | -f)
  free | awk 'NR == 2 {printf "%.2f", ($7/1024)}'
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
