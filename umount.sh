#!/bin/bash
set -uo pipefail

# Explicitly declare our LV array
declare -A LV

# Load config
if [ -e ./config ]; then
  . ./config
fi

umount -R /mnt
vgchange -an
cryptsetup close "$VGNAME"
