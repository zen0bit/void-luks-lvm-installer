#!/bin/bash
set -euxo pipefail

declare -A LV

# Load config
if [ -r ./config ]; then
  . ./config
else
  echo 'Must supply config file' >&2
  exit 1
fi

umount -R /mnt
vgchange -an
cryptsetup close "$VGNAME"
