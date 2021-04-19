#!/bin/bash

print_usage() {
  cat <<-TEXT
Usage: ${0##*/} [-h|-r|-s|-w] [r|b|h|a]

   -h, --help     this message
   -s, --status   show current state
   -r, --ro       remount as read-only
   -w, --rw       remount as read-write

    r, root       / (reboot required to apply!)
    b, boot       /boot partition
    m, mobro      /mobro partition
    a, all        /, /boot and /mobro
TEXT
}

get_overlay_now() {
  grep -q "boot=overlay" /proc/cmdline
}

get_overlay_conf() {
  grep -q "boot=overlay" /boot/cmdline.txt
}

get_bootro_now() {
  findmnt /boot | grep -q " ro,"
}

get_mobroro_now() {
  findmnt /mobro | grep -q " ro,"
}

get_bootro_conf() {
  grep /boot /etc/fstab | grep -q "defaults.*,ro "
}

enable_overlayfs() {
  KERN=$(uname -r)
  INITRD=initrd.img-"$KERN"-overlay

  # mount the boot partition as writable if it isn't already
  if get_bootro_now; then
    if ! mount -o remount,rw /boot 2>/dev/null; then
      echo "Unable to mount boot partition as writable - cannot enable"
      return 1
    fi
    BOOTRO=yes
  else
    BOOTRO=no
  fi

  cat >/etc/initramfs-tools/scripts/overlay <<'EOF'
# Local filesystem mounting			-*- shell-script -*-

#
# This script overrides local_mount_root() in /scripts/local
# and mounts root as a read-only filesystem with a temporary (rw)
# overlay filesystem.
#

. /scripts/local

local_mount_root()
{
	local_top
	local_device_setup "${ROOT}" "root file system"
	ROOT="${DEV}"

	# Get the root filesystem type if not set
	if [ -z "${ROOTFSTYPE}" ]; then
		FSTYPE=$(get_fstype "${ROOT}")
	else
		FSTYPE=${ROOTFSTYPE}
	fi

	local_premount

	# CHANGES TO THE ORIGINAL FUNCTION BEGIN HERE
	# N.B. this code still lacks error checking

	modprobe ${FSTYPE}
	checkfs ${ROOT} root "${FSTYPE}"

	# Create directories for root and the overlay
	mkdir /lower /upper

	# Mount read-only root to /lower
	if [ "${FSTYPE}" != "unknown" ]; then
		mount -r -t ${FSTYPE} ${ROOTFLAGS} ${ROOT} /lower
	else
		mount -r ${ROOTFLAGS} ${ROOT} /lower
	fi

	modprobe overlay || insmod "/lower/lib/modules/$(uname -r)/kernel/fs/overlayfs/overlay.ko"

	# Mount a tmpfs for the overlay in /upper
	mount -t tmpfs tmpfs /upper
	mkdir /upper/data /upper/work

	# Mount the final overlay-root in $rootmnt
	mount -t overlay \
	    -olowerdir=/lower,upperdir=/upper/data,workdir=/upper/work \
	    overlay ${rootmnt}
}
EOF

  # add the overlay to the list of modules
  if ! grep overlay /etc/initramfs-tools/modules >/dev/null; then
    echo overlay >>/etc/initramfs-tools/modules
  fi

  # build the new initramfs
  update-initramfs -c -k "$KERN"

  # rename it so we know it has overlay added
  mv /boot/initrd.img-"$KERN" /boot/"$INITRD"

  # there is now a modified initramfs ready for use...

  # modify config.txt
  sed -i /boot/config.txt -e "/initramfs.*/d"
  echo initramfs "$INITRD" >>/boot/config.txt

  # modify command line
  if ! grep -q "boot=overlay" /boot/cmdline.txt; then
    sed -i /boot/cmdline.txt -e "s/^/boot=overlay /"
  fi

  if [ "$BOOTRO" = "yes" ]; then
    if ! mount -o remount,ro /boot 2>/dev/null; then
      echo "Unable to remount boot partition as read-only"
    fi
  fi
}

disable_overlayfs() {
  KERN=$(uname -r)
  # mount the boot partition as writable if it isn't already
  if get_bootro_now; then
    if ! mount -o remount,rw /boot 2>/dev/null; then
      echo "Unable to mount boot partition as writable - cannot disable"
      return 1
    fi
    BOOTRO=yes
  else
    BOOTRO=no
  fi

  # modify config.txt
  sed -i /boot/config.txt -e "/initramfs.*/d"
  update-initramfs -d -k "${KERN}-overlay"

  # modify command line
  sed -i /boot/cmdline.txt -e "s/\(.*\)boot=overlay \(.*\)/\1\2/"

  if [ "$BOOTRO" = "yes" ]; then
    if ! mount -o remount,ro /boot 2>/dev/null; then
      echo "Unable to remount boot partition as read-only"
    fi
  fi
}

remount_ro() {
  mount -o remount,ro "$1"
}

remount_rw() {
  mount -o remount,rw "$1"
}

print_status() {
  local color_ro="\e[0;31m"
  local color_rw="\e[0;32m"
  local color_path="\033[38;5;6m"
  local color_white="\033[00m"

  local overlay_conf="RW"
  local overlay_color_conf=$color_rw
  if get_overlay_conf; then
    overlay_conf="RO"
    overlay_color_conf=$color_ro
  fi
  local overlay_status="RW"
  local overlay_color_status=$color_rw
  if get_overlay_now; then
    overlay_status="RO"
    overlay_color_status=$color_ro
  fi
  local boot_status="RW"
  local boot_color=$color_rw
  if get_bootro_now; then
    boot_status="RO"
    boot_color=$color_ro
  fi
  local mobro_status="RW"
  local mobro_color=$color_rw
  if get_mobroro_now; then
    mobro_status="RO"
    mobro_color=$color_ro
  fi

  printf "${color_path}/${color_white}      : ${overlay_color_status}%s ${color_white}(${overlay_color_conf}%s ${color_white}on next boot)\n" "$overlay_status" "$overlay_conf"
  printf "${color_path}/boot${color_white}  : ${boot_color}%s\n" "$boot_status"
  printf "${color_path}/mobro${color_white} : ${mobro_color}%s\n" "$mobro_status"
}

# Check whether user requests help
[ "$1" = "--help" -o "$1" = "-h" ] && {
  print_usage
  exit 0
}

[ "$(id -u)" -eq 0 ] || {
  echo "ERROR: this script requires root privileges"
  exit 1
}

case "$1" in
--ro | -r)
  ACTION=RO
  ;;
--rw | -w)
  ACTION=RW
  ;;
--status | -s)
  ACTION=status
  ;;
*)
  print_usage
  exit 1
  ;;
esac

[ "$ACTION" = "status" ] && {
  print_status
  exit 0
}

case "$2" in
r | root)
  PARTITION=/
  ;;
b | boot)
  PARTITION=/boot
  ;;
m | mobro)
  PARTITION=/mobro
  ;;
a | all)
  PARTITION=all
  ;;
*)
  print_usage
  exit 1
  ;;
esac

overlay_conf="RW"
if get_overlay_conf; then
  overlay_conf="RO"
fi
if [ "$PARTITION" = "/" ] || [ "$PARTITION" = "all" ]; then
  if [ "$ACTION" != "$overlay_conf" ]; then
    if [ "$ACTION" = "RW" ]; then
      disable_overlayfs
    elif [ "$ACTION" = "RO" ]; then
      enable_overlayfs
    fi
  fi
fi

if [ "$PARTITION" = "/boot" ] || [ "$PARTITION" = "all" ]; then
  if [ "$ACTION" = "RW" ]; then
    remount_rw /boot
  elif [ "$ACTION" = "RO" ]; then
    remount_ro /boot
  fi
fi

if [ "$PARTITION" = "/mobro" ] || [ "$PARTITION" = "all" ]; then
  if [ "$ACTION" = "RW" ]; then
    remount_rw /mobro
  elif [ "$ACTION" = "RO" ]; then
    remount_ro /mobro
  fi
fi

print_status

exit 0
