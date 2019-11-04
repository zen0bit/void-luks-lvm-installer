#!/bin/bash
set -euxo pipefail

set -u
GPGPUBKEY="$1"
COPYKEY="${2-}"
set +u

# Explicitly declare our LV array
declare -A LV

# Load config
if [ -e ./config ]; then
  . ./config
fi

# Detect if we're in UEFI or legacy mode
[ -d /sys/firmware/efi ] && UEFI=1

if [ $UEFI ]; then
  BOOTPART="2"
  DATAPART="3"
else
  BOOTPART="1"
  DATAPART="2"
fi

function copykey() {
    mntdir=$(mktemp -d)
    mount -o ro /dev/${DEVNAME}p${BOOTPART} "$mntdir"
    cp "$mntdir/luks.key.gpg" .
    umount "$mntdir"
    rmdir "$mntdir"
}

function setupgpg() {
    gpg2 --import "$GPGPUBKEY"
    gpg2 --card-status
}

function decryptluks() {
    gpg2 -d luks.key.gpg | cryptsetup -d - open /dev/${DEVNAME}p${DATAPART} "$VGNAME"
}

function mountfs() {
    vgchange -ay

    mount /dev/mapper/${VGNAME}-root /mnt
    for dir in dev proc sys boot; do
      mkdir -p /mnt/${dir}
    done

    # Remove root and sort keys
    unset LV[root]
    for FS in $(for key in "${!LV[@]}"; do printf '%s\n' "$key"; done | sort); do
      mkdir -p /mnt/${FS}
      mount /dev/mapper/${VGNAME}-${FS/\//_} /mnt/${FS}
    done

    if [ $UEFI ]; then
      mount /dev/${DEVNAME}p${BOOTPART} /mnt/boot
      mkdir /mnt/boot/efi
      mount /dev/${DEVNAME}p1 /mnt/boot/efi
    else
      mount /dev/${DEVNAME}p${BOOTPART} /mnt/boot
    fi

    for fs in dev proc sys; do
      mount -o bind /${fs} /mnt/${fs}
    done
}

if [ -n "$COPYKEY" ]; then
    setupgpg
    decryptluks
    copykey
fi
mountfs
