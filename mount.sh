#!/bin/bash
set -euxo pipefail

# Decrypt LUKS and mount filesystems

declare -A LV
UEFI=

# Load config
if [ -r ./config ]; then
  . ./config
else
  echo 'Must supply config file' >&2
  exit 1
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

cryptsetup open /dev/${DEVNAME}p${DATAPART} "$VGNAME" || true

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
