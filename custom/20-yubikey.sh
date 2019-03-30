#!/bin/bash

# Install YubiKey udev rule
mkdir -p /etc/udev/rules.d
cat << EOF > /etc/udev/rules.d/70-yubikey.rules
ACTION!="add|change", GOTO="u2f_end"
# Yubico YubiKey
ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0116", GROUP="plugdev", MODE="0660"
LABEL="u2f_end"
EOF

groupadd --system --force plugdev

if [ -n "$USERACCT" ]; then
  usermod -aG plugdev ${USERACCT}
fi
