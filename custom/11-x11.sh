#!/bin/bash

# Enable nonfree repo for NVIDIA drivers
#xbps-install -Sy void-repo-nonfree
# XXX: Not installing nvidia because it breaks scdaemon/gpg in initramfs

xbps-install -Sy compton rxvt-unicode transset xclip xdotool xf86-video-intel \
  xinput xfontsel xmessage xorg-fonts xorg-minimal xprop xrandr xrdb xsel xset \
  xsetroot xterm xtitle xwinwrap \
|| true

# Blacklist nouveau driver since it causes kernel panic
sed -i 's:\(^GRUB_CMDLINE_LINUX.*\)"$:\1 modprobe.blacklist=nouveau":' /etc/default/grub
