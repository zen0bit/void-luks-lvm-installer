#!/bin/bash

xbps-install -Sy curl dhcpcd openbsd-netcat wifi-firmware wget wpa_supplicant || true

# Enable services
ln -sfn /etc/sv/dhcpcd /etc/runit/runsvdir/default/
ln -sfn /etc/sv/wpa_supplicant /etc/runit/runsvdir/default/

# Download and compile Surf
xbps-install -Sy gcr-devel glib-devel rofi webkit2gtk-devel || true
su -w SSH_AUTH_SOCK - ${USERACCT} <<'EOF'
export GIT_SSH_COMMAND='ssh -o Hostname=172.16.1.5 -o Port=10022'
test -d ~/Projects/surf || git clone git@git.imiric.lan:ivan/surf.git ~/Projects/surf
(cd ~/Projects/surf && make install)

# st is needed for surf's download functionality
test -d ~/Projects/st || git clone git@git.imiric.lan:ivan/st.git ~/Projects/st
(cd ~/Projects/st && make install)
EOF
