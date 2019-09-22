#!/bin/bash

xbps-install -Sy bind-utils chromium dhcpcd firefox mktorrent net-tools nmap \
  openbsd-netcat tcpdump wifi-firmware wpa_supplicant wireshark-qt youtube-dl || true

# Enable services
ln -sfn /usr/share/dhcpcd/hooks/10-wpa_supplicant /usr/libexec/dhcpcd-hooks
ln -sfn /etc/sv/dhcpcd /etc/runit/runsvdir/default/

# Download and compile Surf
xbps-install -Sy gcr-devel glib-devel rofi webkit2gtk-devel || true
export GIT_SSH_COMMAND='ssh -o Hostname=172.16.1.5 -o Port=10022' \
  SSH_AUTH_SOCK=/tmp/.gnupg/S.gpg-agent.ssh \
  PROJECTS_DIR=/home/${USERACCT}/Projects
mkdir -p "$PROJECTS_DIR"
test -d "$PROJECTS_DIR/surf" || git clone git@git.imiric.lan:ivan/surf.git "$PROJECTS_DIR/surf"
(cd "$PROJECTS_DIR/surf" && make install)

# st is needed for surf's download functionality
test -d "$PROJECTS_DIR/st" || git clone git@git.imiric.lan:ivan/st.git "$PROJECTS_DIR/st"
(cd "$PROJECTS_DIR/st" && make install)

chown -R ${USERACCT}: /home/${USERACCT}/Projects
