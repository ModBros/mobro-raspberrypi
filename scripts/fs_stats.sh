#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [OPTION] [PARTITION]
  options:
   -h, --help        This message
   -u, --used        Used space of given filesystem in MB
   -a, --available   Available space of given filesystem in MB
   -l, --load        Usage of given filesystem in %
   -m, --mount       The mount point of the fs
   -f, --filesystem  The filesystem
   -s, --status      Mounted RW or RO
   -j, --json        all values in json format

  partitions:
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

get_used() {
  echo "$1" | awk 'NR == 1 {printf "%.2f", $3/1024}'
}

get_available() {
  echo "$1" | awk 'NR == 1 {printf "%.2f", $4/1024}'
}

get_load() {
  echo "$1" | awk 'NR == 1 {print $5}'
}

get_mount() {
  echo "$1" | awk 'NR == 1 {print $6}'
}

get_fs() {
  echo "$1" | awk 'NR == 1 {print $1}'
}

get_status() {
  if [ "$1" = "/" ]; then
    get_overlay_now
    if get_overlay_now; then
      echo -n "read-only"
    else
      echo -n "read-write"
    fi
  else
    if get_ro_now "$1"; then
      echo -n "read-only"
    else
      echo -n "read-write"
    fi
  fi
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
  get_used "$(df | grep "$PARTITION")"
  ;;
--available | -a)
  get_available "$(df | grep "$PARTITION")"
  ;;
--load | -l)
  get_load "$(df | grep "$PARTITION")"
  ;;
--mount | -m)
  get_mount "$(df | grep "$PARTITION")"
  ;;
--filesystem | -f)
  get_fs "$(df | grep "$PARTITION")"
  ;;
--status | -s)
  get_status "$PARTITION"
  ;;
--json | -j)
  DF_RESPONSE=$(df | grep "$PARTITION")
  printf '{"status":"%s","mounted":"%s","filesystem":"%s","used":%f,"available":%f,"usage":%i}\n' \
    "$(get_status "$DF_RESPONSE")" \
    "$(get_mount "$DF_RESPONSE")" \
    "$(get_fs "$DF_RESPONSE")" \
    "$(get_used "$DF_RESPONSE")" \
    "$(get_available "$DF_RESPONSE")" \
    "$(get_load "$DF_RESPONSE")"
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
