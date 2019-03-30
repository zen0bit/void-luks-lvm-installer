#!/bin/bash

xbps-install -Sy gnupg2 gnupg2-scdaemon pcsclite pcsc-ccid || true

# Enable pcscd service for smartcard access
ln -sfn /etc/sv/pcscd /etc/runit/runsvdir/default/

# Dracut relies on 'gpg' being available, otherwise it doesn't enable the
# crypt-gpg module in the initramfs image.
ln -sfn /usr/bin/gpg2 /usr/bin/gpg

# Import the main GPG identity for the user account
su - ${USERACCT} -c 'gpg2 --import /etc/dracut.conf.d/crypt-public-key.gpg'
