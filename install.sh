#!/bin/bash
set -euxo pipefail

# Install a Void Linux system to /mnt mounted on a LUKS encrypted
# volume protected by a GPG encrypted key.
#
# A GPG identity (public key) file is expected as first argument,
# whose associated private keys should be on a GnuPG smartcard device
# (YubiKey, etc.).
#
# Usage:
# install.sh <path/to/gpg.pub.key>

set -u
GPGPUBKEY="$1"
set +u

./mkpart.sh "$GPGPUBKEY"
./mount.sh "$GPGPUBKEY"
./install-base.sh
./install-custom.sh
./reconfigure.sh

sync
