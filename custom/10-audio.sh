#!/bin/bash

xbps-install -Sy alsa-utils dbus pamixer pavucontrol pulseaudio sox || true

# Enable dbus for pulseaudio
ln -sfn /etc/sv/dbus /var/service/
ln -sfn /etc/sv/pulseaudio /var/service/

if [ -n "$USERACCT" ]; then
  usermod -aG audio ${USERACCT}
fi
