#!/bin/bash

xbps-install -Sy curl dhcpcd openbsd-netcat wifi-firmware wget wpa_supplicant || true

# Enable services
ln -sfn /etc/sv/dhcpcd /etc/runit/runsvdir/default/
ln -sfn /etc/sv/wpa_supplicant /etc/runit/runsvdir/default/

# Download and compile Surf
xbps-install -Sy gcr-devel glib-devel rofi webkit2gtk-devel || true
test -d ~/Projects/surf || (git clone git@github.com:imiric/surf.git ~/Projects/surf)
(cd ~/Projects/surf && make install)
