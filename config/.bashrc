
set_bash_prompt() {
  local ofs_mode ofs_color
  if $(grep -q "boot=overlay" /proc/cmdline); then
    ofs_mode="ro"
    ofs_color="\[\033[38;5;1m\]"
  else
    ofs_mode="rw"
    ofs_color="\[\033[38;5;2m\]"
  fi

  local boot_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/boot .*(\(r[w|o]\).*/\1/p")
  local boot_color
  if [ "$boot_mode" = "ro" ]; then
    boot_color="\[\033[38;5;1m\]"
  else
    boot_color="\[\033[38;5;2m\]"
  fi

  local orange="\[\033[38;5;166m\]"
  local path="\[\033[38;5;6m\]"
  local white="\[\033[00m\]"
  local grey="\[\033[38;5;8m\]"

  export PS1="${orange}\u@\h${white}[${ofs_color}${ofs_mode}${white}|${boot_color}${boot_mode}${white}]:${path}\w${white}\$ "
}

set_default_fun() {
  sudo rm -f /mobro/skip_service
  sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --rw mobro
  sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --ro root
  sudo dhcpcd --release
  sudo systemctl stop dhcpcd
  sudo rm -rf /var/lib/dhcpcd5/*
  sudo reboot
}

alias fsmount='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh'
alias status='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --status'
alias set_boot_configurable='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --rw boot'
alias set_root_configurable='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --rw root && sudo touch /mobro/skip_service && sudo reboot'
alias set_default='set_default_fun'

PROMPT_COMMAND=set_bash_prompt

# welcome message
echo -e ''
echo -e '\033[38;5;160m ######      ######     #######'
echo -e '\033[38;5;160m #######    #######   ##########  \033[00m @@@@@@@@@@     @@@@@@@@@@@      @@@@@@@@'
echo -e '\033[38;5;160m ########  ########  ######   ### \033[00m @@@@@@@@@@@@   @@@@@@@@@@@@    @@@@@@@@@@'
echo -e '\033[38;5;160m ##################  #####     ### \033[00m @@@@    @@@@  @@@@   @@@@    @@@@    @@@@'
echo -e '\033[38;5;160m ###### #### ######  #####     #### \033[00m @@@@@@@@@    @@@@@@@@@@@@   @@@@    @@@@'
echo -e '\033[38;5;160m ######      ######  #####     ##### \033[00m @@    @@@@  @@@@    @@@@@  @@@@    @@@@'
echo -e '\033[38;5;160m ######      ######  ######   ######  \033[00m @@@@@@@@@  @@@@    @@@@@   @@@@@@@@@@'
echo -e '\033[38;5;160m ######      ######   #############    \033[00m @@@@@@    @@@@    @@@@@    @@@@@@@@'
echo -e '\033[38;5;160m ######      ######    ###########'

echo -en "\033[00m"
cat <<-TEXT
                                                                  by ModBros
 * Website/Forum : http://mod-bros.com
 * GitHub        : http://github.com/modbros
 * YouTube       : http://youtube.com/modbros


TEXT

echo -e '\033[38;5;160m! CAUTION !'
echo -e '\033[00mThis image uses OverlayFS on \033[38;5;6m/\033[00m, while \033[38;5;6m/boot\033[00m is mounted read-only'
echo -e '\033[00mChanges in this mode are not possible or will be lost after shutdown!'
echo ''
echo -e '\033[00mUseful commands:'
echo -e ' \033[38;5;6mstatus\033[00m                  Get current mount status for each partition'
echo -e ' \033[38;5;6mset_boot_configurable\033[00m   Allow modifications on /boot'
echo -e ' \033[38;5;6mset_root_configurable\033[00m*  Disable OverlayFS + MoBro to allow modifications'
echo -e ' \033[38;5;6mset_default\033[00m*            Set back to defaults and enable MoBro'
echo ''
echo -e '\033[00m * causes a reboot'
echo ''
printf "\e[0;32m%s\033[00m%s\n" "rw" " = mounted with write permission"
printf "\e[0;31m%s\033[00m%s\n" "ro" " = OverlayFs enabled or mounted read-only (changes will be lost!)"
echo -en "\033[38;5;6m"
cat <<-TEXT


                        root
 filesystem status ->     | /boot
                          |   |
TEXT
#modbros@mobro-raspberrypi[rw|rw]:~$
