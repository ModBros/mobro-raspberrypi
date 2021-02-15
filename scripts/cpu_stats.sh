#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [OPTION]
   -h, --help          This message
   -l, --load          Total CPU usage in %
   -t, --temperature   Temperature in 'C
   -c, --clock         The current clock in MHz
   -p, --processors    The number of processors (cores)
   -j, --json          all values in json format
TEXT
}

get_load() {
  awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else {printf "%.2f", (($2+$4-u1) * 100 / (t-t1))}; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)
}

get_temperature() {
  printf "%.2f" "$(sed "s/\(...\)$/.\1/" </sys/class/thermal/thermal_zone0/temp)"
}

get_clock() {
  echo $(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000))
}

get_num_processors() {
  nproc --all
}

[ "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

case "$1" in
--load | -l)
  #cat <(grep 'cpu ' /proc/stat) <(sleep 0.1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{printf "%.1f", ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5)}'
  get_load
  ;;
--temperature | -t)
  get_temperature
  ;;
--clock | -c)
  get_clock
  ;;
--processors | -p)
  get_num_processors
  ;;
--json | -j)
  printf '{"cores":%i,"temperature":%f,"usage":%f,"clock":%i}\n' "$(get_num_processors)" "$(get_temperature)" "$(get_load)" "$(get_clock)"
  ;;
*)
  print_usage
  exit 1
  ;;
esac

exit 0
