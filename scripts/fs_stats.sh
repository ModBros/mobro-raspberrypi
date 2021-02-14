#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [-h|-u|-f|-l] [boot|root|home]
   -h, --help        This message
   -u, --used        Used space of given filesystem in MB
   -a, --available   Available space of given filesystem in MB
   -l, --load        Usage of given filesystem in %
   -m, --mount       The mount point of the fs
   -f, --filesystem  The filesystem
   -s, --status      Mounted RW or RO

    r, root          the root fs
    b, boot          the boot partition
    h, home          the home partition
TEXT
}

get_ro_now() {
  findmnt "$1" | grep -q " ro,"
}

get_overlay_now() {
  grep -q "boot=overlay" /proc/cmdline
}

[ "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

case "$2" in
r | root)
  PARTITION=/
  ;;
b | boot)
  PARTITION=/boot
  ;;
h | home)
  PARTITION=/home
  ;;
*)
  print_usage
  exit 1
  ;;
esac

case "$1" in
--used | -u)
  df | grep "$PARTITION" | awk 'NR == 1 {printf "%.2f", $3/1024}'
  ;;
--available | -a)
  df | grep "$PARTITION" | awk 'NR == 1 {printf "%.2f", $4/1024}'
  ;;
--load | -l)
  df | grep "$PARTITION" | awk 'NR == 1 {printf "%i", $5}'
  ;;
--mount | -m)
  df | grep "$PARTITION" | awk 'NR == 1 {printf "%s", $6}'
  ;;
--filesystem | -f)
  df | grep "$PARTITION" | awk 'NR == 1 {printf "%s", $1}'
  ;;
--status | -s)
  if [ "$PARTITION" = "/" ]; then
    get_overlay_now
    if get_overlay_now; then
      echo -n "read-only"
    else
      echo -n "read-write"
    fi
  else
    if get_ro_now $PARTITION; then
      echo -n "read-only"
    else
      echo -n "read-write"
    fi
  fi
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
