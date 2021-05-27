
set_bash_prompt() {
  local ofs_mode ofs_color
  if $(grep -q "boot=overlay" /proc/cmdline); then
    ofs_mode="ro"
    ofs_color="\[\033[38;5;1m\]"
  else
    ofs_mode="rw"
    ofs_color="\[\033[38;5;2m\]"
  fi

  local orange="\[\033[38;5;166m\]"
  local path="\[\033[38;5;6m\]"
  local white="\[\033[00m\]"
  local grey="\[\033[38;5;8m\]"

  export PS1="${orange}\u@\h${white}[${ofs_color}${ofs_mode}${white}]:${path}\w${white}\$ "
}

alias fsmount='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh'
alias status='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --status'
alias set_configurable='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --rw all && sudo touch /mobro/skip_service && sudo reboot'
alias set_locked='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh --ro root && sudo rm -f /mobro/skip_service && sudo reboot'

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
echo -e '\033[00mAll applied changes in this mode will be lost after shutdown or reboot!'
echo ''
echo -e '\033[00mCurrent mount status for each partition:   \033[38;5;6mstatus'
echo -e '\033[00mDisable OverlayFS and allow modifications: \033[38;5;6mset_configurable \033[00m(reboot!)'
echo -e '\033[00mSwitch back to enabled OverlayFS:          \033[38;5;6mset_locked \033[00m(reboot!)'
echo ''
printf "\e[0;32m%s\033[00m%s\n" "rw" " = mounted with write permission"
printf "\e[0;31m%s\033[00m%s\n" "ro" " = OverlayFs enabled or mounted read-only (changes will be lost!)"
echo -en "\033[38;5;6m"
cat <<-TEXT


                root filesystem status
                          |
                          V
TEXT
#modbros@mobro-raspberrypi[rw]:~$
