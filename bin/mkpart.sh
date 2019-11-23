#!/bin/bash
set -euxo pipefail

# Create LUKS and LVM partitions

declare -A LV
UEFI=

# Load config or defaults
if [ -r ./config ]; then
  . ./config
else
  echo 'Must supply config' >&2
  exit 1
fi

# Detect if we're in UEFI or legacy mode
[ -d /sys/firmware/efi ] && UEFI=1

# Detect if we're on an Intel system
CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk '{print $3}' | uniq)
if [ $CPU_VENDOR = "GenuineIntel" ]; then
  PKG_LIST="$PKG_LIST intel-ucode"
fi

# Wipe entire drive
dd if=/dev/zero of=/dev/${DEVNAME} bs=1M count=100
if [ $UEFI ]; then
  parted /dev/${DEVNAME} mklabel gpt
  # EFI partition
  parted -a optimal /dev/${DEVNAME} mkpart primary 2048s 100M
  # Unencrypted /boot partition
  # This needs to be unencrypted since it contains the initramfs
  # image which has GnuPG to be able to decrypt the LUKS key and the
  # rest of the system.
  parted -a optimal /dev/${DEVNAME} mkpart primary 100M 1124M
  # Encrypted LUKS partition for LVM
  parted -a optimal /dev/${DEVNAME} mkpart primary 1124M 100%
else
  parted /dev/${DEVNAME} mklabel msdos
  parted -a optimal /dev/${DEVNAME} mkpart primary 2048s 1G
  parted -a optimal /dev/${DEVNAME} mkpart primary 1G 100%
fi
parted /dev/${DEVNAME} set 1 boot on

if [ $UEFI ]; then
  BOOTPART="2"
  DATAPART="3"
else
  BOOTPART="1"
  DATAPART="2"
fi

echo "[!] Encrypt root partition"
cryptsetup ${CRYPTSETUP_OPTS} luksFormat -c aes-xts-plain64 -s 512 /dev/${DEVNAME}p${DATAPART}
echo "[!] Open root partition"
cryptsetup -d - luksOpen /dev/${DEVNAME}p${DATAPART} void

# Create volume group
pvcreate /dev/mapper/void
vgcreate ${VGNAME} /dev/mapper/void
for FS in ${!LV[@]}; do
  lvcreate -L ${LV[$FS]} -n ${FS/\//_} ${VGNAME}
done
if [ $SWAP -eq 1 ]; then
  lvcreate -L ${SWAPSIZE} -n swap ${VGNAME}
fi

# Format filesystems
if [ $UEFI ]; then
  mkfs.vfat /dev/${DEVNAME}p1
fi
mkfs.ext2 -L boot /dev/${DEVNAME}p${BOOTPART}
for FS in ${!LV[@]}; do
  mkfs.ext4 -L ${FS/\//_} /dev/mapper/${VGNAME}-${FS/\//_}
done
if [ $SWAP -eq 1 ]; then
  mkswap -L swap /dev/mapper/${VGNAME}-swap
fi
