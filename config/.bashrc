set_bash_prompt() {
  local ofs_mode ofs_color
  if $(grep -q "boot=overlay" /proc/cmdline); then
    ofs_mode="ro"
    ofs_color="\[\e[0;31m\]"
  else
    ofs_mode="rw"
    ofs_color="\[\e[0;32m\]"
  fi

  local boot_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/boot .*(\(r[w|o]\).*/\1/p")
  local boot_color
  if [ "$boot_mode" = "ro" ]; then
    boot_color="\[\e[0;31m\]"
  else
    boot_color="\[\e[0;32m\]"
  fi

  local home_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/home .*(\(r[w|o]\).*/\1/p")
  local home_color
  if [ "$home_mode" = "ro" ]; then
    home_color="\[\e[0;31m\]"
  else
    home_color="\[\e[0;32m\]"
  fi

  local cpuTemp0=$(cat /sys/class/thermal/thermal_zone0/temp)
  local temp=$(($cpuTemp0 / 1000))
  local cpu_color
  if [ $temp -gt 70 ]; then
    cpu_color="\[\e[0;31m\]"
  elif [ $temp -gt 60 ]; then
    cpu_color="\[\e[0;33m\]"
  else
    cpu_color="\[\e[0;32m\]"
  fi

  local orange="\[\033[38;5;166m\]"
  local path="\[\033[38;5;6m\]"
  local white="\[\033[00m\]"
  local grey="\[\033[38;5;8m\]"

  export PS1="${orange}\u@\h${white}[${cpu_color}${temp}'C${white}][${ofs_color}${ofs_mode}${white}|${boot_color}${boot_mode}${white}|${home_color}${home_mode}${white}]:${path}\w${white}\$ "
}

alias fsmount='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh'

PROMPT_COMMAND=set_bash_prompt

# welcome message
echo -en "\033[38;5;166m"
cat <<-TEXT

 __  __         ____
|  \\/  |       |  _ \\
| \\  / |  ___  | |_) | _ __  ___
| |\\/| | / _ \\ |  _ < | '__|/ _ \\
| |  | || (_) || |_) || |  | (_) |
|_|  |_| \\___/ |____/ |_|   \\___/
TEXT
echo -en "\033[00m"
cat <<-TEXT
                        by ModBros

* Website/Forum : http://mod-bros.com
* GitHub        : http://github.com/modbros
* YouTube       : http://youtube.com/modbros

! CAUTION !
this image uses OverlayFS on /, while /boot and /home are mounted read-only
all applied changes in this mode will be lost after reboot!

the current mount status is visible directly from the command prompt
to toggle between mounting modes execute 'fsmount'

TEXT
printf "\e[0;32m%s\033[00m%s\n" "rw" " = mounted with write permission"
printf "\e[0;31m%s\033[00m%s\n" "ro" " = OverlayFs enabled or mounted read-only (changes will be lost!)"
echo -en "\033[38;5;6m"
cat <<-TEXT

                            /boot
                        root  | /home
                          |   |  |
TEXT
# modbros@mobro-raspberrypi[rw|ro|ro]:~$