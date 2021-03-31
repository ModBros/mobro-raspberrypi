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

  local home_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/home .*(\(r[w|o]\).*/\1/p")
  local home_color
  if [ "$home_mode" = "ro" ]; then
    home_color="\[\033[38;5;1m\]"
  else
    home_color="\[\033[38;5;2m\]"
  fi

  local orange="\[\033[38;5;166m\]"
  local path="\[\033[38;5;6m\]"
  local white="\[\033[00m\]"
  local grey="\[\033[38;5;8m\]"

  export PS1="${orange}\u@\h${white}[${ofs_color}${ofs_mode}${white}|${boot_color}${boot_mode}${white}|${home_color}${home_mode}${white}]:${path}\w${white}\$ "
}

alias fsmount='sudo /home/modbros/mobro-raspberrypi/scripts/fsmount.sh'

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
echo -e '\033[00mThis image uses OverlayFS on \033[38;5;6m/\033[00m, while \033[38;5;6m/boot\033[00m and \033[38;5;6m/home\033[00m are mounted read-only'
echo -e '\033[00mAll applied changes in this mode will be lost after reboot!'
echo ''
echo -e '\033[00mThe current mount status is visible directly from the command prompt'
echo -e '\033[00mto toggle between mounting modes execute \033[38;5;6mfsmount'
echo ''

printf "\e[0;32m%s\033[00m%s\n" "rw" " = mounted with write permission"
printf "\e[0;31m%s\033[00m%s\n" "ro" " = OverlayFs enabled or mounted read-only (changes will be lost!)"
echo -en "\033[38;5;6m"
cat <<-TEXT

                            /boot
                        root  | /home
                          |   |  |
TEXT
# modbros@mobro-raspberrypi[rw|ro|ro]:~$
