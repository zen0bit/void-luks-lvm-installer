#!/bin/bash
set -euxo pipefail

# Install base Void Linux packages

declare -A LV
UEFI=

# Load config or defaults
if [ -r ./config ]; then
  . ./config
else
  echo 'Must supply config file' >&2
  exit 1
fi

# Detect if we're in UEFI or legacy mode
[ -d /sys/firmware/efi ] && UEFI=1
if [ $UEFI ]; then
  PKG_LIST="$PKG_LIST grub-x86_64-efi efibootmgr"
fi

if [ $UEFI ]; then
  BOOTPART="2"
  DATAPART="3"
else
  BOOTPART="1"
  DATAPART="2"
fi

# Detect if we're on an Intel system
CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk '{print $3}' | uniq)
if [ $CPU_VENDOR = "GenuineIntel" ]; then
  PKG_LIST="$PKG_LIST intel-ucode"
fi

mkdir -p /mnt/var/db/xbps/keys/
cp -a /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

xbps-install -y -S \
  -R https://alpha.de.repo.voidlinux.org/current \
  -R https://alpha.de.repo.voidlinux.org/current/nonfree \
  -r /mnt $PKG_LIST

# Do a bit of customization
echo "[!] Setting root password"
passwd -R /mnt root
echo $HOSTNAME > /mnt/etc/hostname
echo "TIMEZONE=${TIMEZONE}" >> /mnt/etc/rc.conf
echo "KEYMAP=${KEYMAP}" >> /mnt/etc/rc.conf
echo "TTYS=3" >> /mnt/etc/rc.conf

echo "LANG=$LANG" > /mnt/etc/locale.conf
echo "$LANG $(echo ${LANG} | cut -f 2 -d .)" >> /mnt/etc/default/libc-locales
chroot /mnt xbps-reconfigure -f glibc-locales

# Add fstab entries
echo "LABEL=root  /       ext4    rw,relatime,data=ordered,discard    0 0" > /mnt/etc/fstab
echo "LABEL=boot  /boot   ext2    defaults    0 0" >> /mnt/etc/fstab
for FS in $(for key in "${!LV[@]}"; do printf '%s\n' "$key"; done| sort); do
  echo "LABEL=${FS/\//_}  /${FS}	ext4    rw,relatime,data=ordered,discard    0 0" >> /mnt/etc/fstab
done
echo "tmpfs       /tmp    tmpfs   size=${TMPSIZE},noexec,nodev,nosuid     0 0" >> /mnt/etc/fstab

if [ $UEFI ]; then
  echo "/dev/${DEVNAME}p1   /boot/efi   vfat    defaults    0 0" >> /mnt/etc/fstab
fi

if [ $SWAP -eq 1 ]; then
  echo "LABEL=swap  none       swap     defaults    0 0" >> /mnt/etc/fstab
fi

# Install grub
cat << EOF >> /mnt/etc/default/grub
GRUB_TERMINAL_INPUT="console"
GRUB_TERMINAL_OUTPUT="console"
GRUB_ENABLE_CRYPTODISK=y
EOF
sed -i 's/GRUB_BACKGROUND.*/#&/' /mnt/etc/default/grub
chroot /mnt grub-install /dev/${DEVNAME}

# Enable LUKS and LVM modules in initramfs
mkdir -p /mnt/etc/dracut.conf.d/
echo 'add_dracutmodules+="crypt lvm"' >> /mnt/etc/dracut.conf.d/00-crypt-lvm.conf

# Register LUKS volume
LUKS_DATA_UUID="$(lsblk -o NAME,UUID | grep ${DEVNAME}p${DATAPART} | awk '{print $2}')"
echo "GRUB_CMDLINE_LINUX=\"rd.vconsole.keymap=${KEYMAP} rd.lvm=1 rd.luks=1 \
rd.luks.allow-discards rd.auto=1 rd.luks.uuid=${LUKS_DATA_UUID}\"" \
  >> /mnt/etc/default/grub

# Add user account
if [ -n "${USERACCT}" ]; then
  useradd -R /mnt -G disk,input,optical,storage,users,video,wheel -m -s /bin/bash ${USERACCT}
  # Enable sudo for users in 'wheel' group
  sed -i 's:^# \(%wheel ALL=(ALL) ALL\)$:\1:' /mnt/etc/sudoers
  echo "[!] Setting password for ${USERACCT}"
  passwd -R /mnt ${USERACCT}
fi

# Set temporary DNS for custom system setup
echo "nameserver 8.8.8.8" > /mnt/etc/resolv.conf
