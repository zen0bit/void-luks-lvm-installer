#!/bin/bash
set -euo pipefail

# Install a Void Linux system on a LUKS encrypted volume mounted at /mnt.

PATH="$PWD/bin:$PATH"

mkpart.sh
mount.sh
install-base.sh
install-custom.sh
reconfigure.sh

sync
