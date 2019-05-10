#!/bin/bash
set -e

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

# Explicitely declare our LV array
declare -A LV

# Load config or defaults
if [ -e ./config ]; then
  . ./config
else
  PKG_LIST="base-system lvm2 cryptsetup grub"
  HOSTNAME="dom1.internal"
  KEYMAP="fr_CH"
  TIMEZONE="Europe/Zurich"
  LANG="en_US.UTF-8"
  DEVNAME="sda"
  VGNAME="vgpool"
  CRYPTSETUP_OPTS=""
  SWAP=0
  SWAPSIZE="16G"
  LV[root]="10G"
  LV[var]="5G"
  LV[home]="512M"
  TMPSIZE="2G"
fi

# Detect if we're in UEFI or legacy mode
[ -d /sys/firmware/efi ] && UEFI=1
if [ $UEFI ]; then
  PKG_LIST="$PKG_LIST grub-x86_64-efi efibootmgr"
fi

# Detect if we're on an Intel system
CPU_VENDOR=$(grep vendor_id /proc/cpuinfo | awk '{print $3}' | uniq)
if [ $CPU_VENDOR = "GenuineIntel" ]; then
  PKG_LIST="$PKG_LIST intel-ucode"
fi

# Import GPG key
export GNUPGHOME=/root/.gnupg
gpg2 --import $GPGPUBKEY

# Create LUKS key and encrypt it with GPG
LUKSKEY="/root/luks.key"
LUKSKEYENC="${LUKSKEY}.gpg"
dd if=/dev/urandom count=64 > "$LUKSKEY"
GPGID=$(gpg2 --with-colons --fingerprint | awk -F: '$1 == "fpr" {print $10;}' | head -1)
echo "$PASSPHRASE" | gpg2 --passphrase-fd 0 --always-trust -r "$GPGID" --encrypt "$LUKSKEY"

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
  parted -a optimal /dev/${DEVNAME} mkpart primary 100M 612M
  # Encrypted LUKS partition for LVM
  parted -a optimal /dev/${DEVNAME} mkpart primary 612M 100%
else
  parted /dev/${DEVNAME} mklabel msdos
  parted -a optimal /dev/${DEVNAME} mkpart primary 2048s 512M
  parted -a optimal /dev/${DEVNAME} mkpart primary 512M 100%
fi
parted /dev/${DEVNAME} set 1 boot on

if [ $UEFI ]; then
  BOOTPART="2"
  DATAPART="3"
else
  BOOTPART="1"
  DATAPART="2"
fi

# Open smart card
gpg2 --card-status

echo "[!] Encrypt root partition"
gpg2 --quiet --decrypt "$LUKSKEYENC" | cryptsetup -d - ${CRYPTSETUP_OPTS} luksFormat -c aes-xts-plain64 -s 512 /dev/${DEVNAME}p${DATAPART}
echo "[!] Open root partition"
gpg2 --quiet --decrypt "$LUKSKEYENC" | cryptsetup -d - luksOpen /dev/${DEVNAME}p${DATAPART} void

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

# Mount filesystems
mount /dev/mapper/${VGNAME}-root /mnt
for dir in dev proc sys boot; do
  mkdir /mnt/${dir}
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
  mkdir -p /mnt/${fs}
  mount -o bind /${fs} /mnt/${fs}
done

# Now install void
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

# Make GPG identity available to Dracut / initramfs
gpg2 --armor --export-options export-minimal --export "$GPGID" > /mnt/etc/dracut.conf.d/crypt-public-key.gpg

cp "$LUKSKEYENC" /mnt/boot/

# Enable Dracut modules to decrypt LUKS keyfile
mkdir -p /mnt/etc/dracut.conf.d/
echo 'add_dracutmodules+="crypt crypt-gpg lvm"' >> /mnt/etc/dracut.conf.d/00-crypt-gpg.conf

# Register LUKS volume
LUKS_DATA_UUID="$(lsblk -o NAME,UUID | grep ${DEVNAME}p${DATAPART} | awk '{print $2}')"
echo "GRUB_CMDLINE_LINUX=\"rd.vconsole.keymap=${KEYMAP} rd.lvm=1 rd.luks=1 \
rd.luks.allow-discards rd.auto=1 rd.luks.uuid=${LUKS_DATA_UUID} rd.luks.key=/luks.key.gpg\"" \
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

# Bind mount the GnuPG socket directory inside the chroot to make GnuPG and SSH
# auth work during the custom setup phase.
mkdir -p /mnt/tmp/.gnupg && chmod 700 $_
mount -o bind $GNUPGHOME /mnt/tmp/.gnupg

# Custom setup of rest of the system
echo "[!] Running custom scripts"
if [ -d ./custom ]; then
  cp -r ./custom /mnt/tmp/
  cp ./config /mnt/var/tmp/

  # If we detect any .sh let's run them in the chroot with the custom
  # config environment
  for SHFILE in /mnt/tmp/custom/*.sh; do
    chroot /mnt env - bash -c \
      "set -o allexport; . /var/tmp/config; set +o allexport; bash /tmp/custom/$(basename $SHFILE)"
  done

  # Then cleanup chroot
  rm -rf /mnt/tmp/custom
fi

# Regenerate GRUB config and initramfs image
# This needs to happen last to take into account any changes during custom setup
KERNEL_VER=$(xbps-query -r /mnt -s linux4 | cut -f 2 -d ' ' | cut -f 1 -d -)
chroot /mnt xbps-reconfigure -f ${KERNEL_VER}
sync
