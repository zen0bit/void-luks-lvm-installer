#!/bin/bash

# Enable nonfree repo for NVIDIA drivers
xbps-install -Sy void-repo-nonfree || true

xbps-install -Sy \
  brillo compton nvidia redshift scrot transset xbacklight xclip xdg-utils xdotool \
  xev xf86-video-intel xhost xinput xfontsel xmessage xorg-fonts xorg-minimal \
  xprop xob xrandr xrdb xsel xset xsetroot xterm xtitle xwinwrap \
|| true

xbps-install -Sy pam-devel
su - ${USERACCT} bash -c '
test -d ~/src/sxlock || git clone https://github.com/lahwaacz/sxlock.git ~/src/sxlock
cd ~/src/sxlock && make
'
xbps-remove -Ry pam-devel
make -C /home/${USERACCT}/src/sxlock install

# Blacklist nouveau driver since it causes kernel panic
sed -i 's:\(^GRUB_CMDLINE_LINUX.*\)"$:\1 modprobe.blacklist=nouveau":' /etc/default/grub

# Fix nvidia breaking scdaemon/gpg in initramfs because it disables drm in the initramfs image.
# Why does scdaemon/gpg depend on drm, and why do I need nvidia drivers in initramfs? ¯\_(ツ)_/¯
mv /usr/lib/dracut/dracut.conf.d/99-nvidia.conf{,.$(date '+%Y%m%d')}

# Make surf the default web browser
if [ -n "${USERACCT}" ]; then
  install -o "$USERACCT" -g "$USERACCT" -Dm755 \
    /tmp/custom/files/www /home/${USERACCT}/.local/bin/www
  install -o "$USERACCT" -g "$USERACCT" -Dm644 \
    /tmp/custom/files/www.desktop /home/${USERACCT}/.local/share/applications/www.desktop
  chown -R ${USERACCT}: /home/${USERACCT}/.local
  su - "${USERACCT}" bash -c \
    'mkdir -p ~/.config; PATH=$HOME/.local/bin:$PATH xdg-settings set default-web-browser www.desktop'
fi
