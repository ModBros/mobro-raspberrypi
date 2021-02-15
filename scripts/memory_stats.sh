#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [OPTION]
   -h, --help         This message
   -l, --load         Memory usage in %
   -t, --total        Total memory in MB
   -u, --used         Used memory in MB
   -a, --available    Available memory in MB
   -c  --cache        Memory used by the page cache and slabs in MB
   -f, --free         Free memory in MB
   -j, --json         all values in json format
TEXT
}

[ "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

get_load() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($3/$2*100)}'
}

get_total() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($2/1024)}'
}

get_used() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($3/1024)}'
}

get_available() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($7/1024)}'
}

get_free() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($4/1024)}'
}

get_cached() {
  echo "$1" | awk 'NR == 2 {printf "%.2f", ($6/1024)}'
}

case "$1" in
--load | -l)
  get_load "$(free)"
  ;;
--total | -t)
  get_total "$(free)"
  ;;
--used | -u)
  get_used "$(free)"
  ;;
--free | -f)
  get_free "$(free)"
  ;;
--available | -a)
  get_available "$(free)"
  ;;
--cache | -c)
  get_cached "$(free)"
  ;;
--json | -j)
  FREE_RESPONSE=$(free)
  printf '{"usage":%.2f,"total":%.2f,"used":%.2f,"free":%.2f,"cache":%.2f,"available":%.2f}\n' \
    "$(get_load "$FREE_RESPONSE")" \
    "$(get_total "$FREE_RESPONSE")" \
    "$(get_used "$FREE_RESPONSE")" \
    "$(get_free "$FREE_RESPONSE")" \
    "$(get_cached "$FREE_RESPONSE")" \
    "$(get_available "$FREE_RESPONSE")"
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
