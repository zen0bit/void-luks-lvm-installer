#!/bin/bash

xbps-install -Sy bluez obexfs || true

# Enable services
ln -sfn /etc/sv/dbus /var/service/
ln -sfn /etc/sv/bluetoothd /var/service/

if [ -n "$USERACCT" ]; then
  usermod -aG bluetooth ${USERACCT}
fi
