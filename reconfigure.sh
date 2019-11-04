#!/bin/bash
set -euo pipefail

# Regenerate GRUB config and initramfs image
KERNEL_VERS=$(xbps-query -r /mnt --regex -s 'linux[45]' | \
  sed -e 's:.*\(linux[45]\{1,\}\.[0-9]\{1,\}\)-.*:\1:' | uniq)
for kv in $KERNEL_VERS; do
    chroot /mnt xbps-reconfigure -f "$kv"
done

# Load config
if [ -e ./config ]; then
  . ./config
fi

chroot /mnt grub-install /dev/${DEVNAME}

GRUB_DEFAULT=$(grep '^GRUB_DEFAULT' /mnt/etc/default/grub | \
  sed -e 's:.*\([45]\.[0-9]\{1,\}[^-]*\).*:\1:')
if [ -n "$GRUB_DEFAULT" ]; then
    ADVMENUID=$(grep 'submenu.*gnulinux-advanced' \
      /mnt/boot/grub/grub.cfg | sed -e "s:.*'\(.*\)'.*:\1:")
    ADVITEMID=$(grep gnulinux-$GRUB_DEFAULT /mnt/boot/grub/grub.cfg | \
      tail -2 | head -1 | sed -e "s:.*\(gnulinux-.*\)'.*:\1:")
    sed -ie 's:^GRUB_DEFAULT=.*:GRUB_DEFAULT="'"${ADVMENUID}>${ADVITEMID}"'":' /mnt/etc/default/grub
    # Do a final reconfigure to update the default
    chroot /mnt xbps-reconfigure -f "$kv"
fi
