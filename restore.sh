#!/bin/bash
set -euo pipefail

set -u
GPGPUBKEY="$1"
BACKUPFILE="$2"
set +u

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

# Partition entire disk according to ./config (read and confirm settings!)
./mkpart.sh "$GPGPUBKEY"

# Restore backup
# TODO: Deal with multiple .tpxz files (and .gpg files as well?)
# Idea: allow passing one or more files in args, and extract them in order.
# This would allow e.g. `./restore.sh pub.key root-*.gpg`.
cat "$BACKUPFILE" | pixz -d | tar -xvpf - -C /mnt/

# Overwrite the LUKS key with the new one created in mkpart.sh
cp luks.key.gpg /mnt/boot/

# Update the LUKS partition UUID
DATAPARTUUID=$(lsblk -no uuid /dev/${DEVNAME}p${DATAPART} | tail -1)
sed -ie 's:rd\.luks\.uuid=\([^ ]*\) :rd.luks.uuid='"$DATAPARTUUID"' :' /mnt/etc/default/grub
