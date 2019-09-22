#!/bin/bash
set -euxo pipefail

function copykey() {
    mount -o ro /dev/nvme0n1p2 /media
    cp /media/luks.key.gpg .
    umount /media
}

function setupgpg() {
    gpg2 --import /root/imiric.gpg.pub
    gpg2 --card-status
}

function decryptluks() {
    gpg2 -d luks.key.gpg | cryptsetup -d - open /dev/nvme0n1p3 void
}

function mountfs() {
    vgchange -ay
    mount /dev/mapper/void-root /mnt
    mount /dev/mapper/void-home /mnt/home
    mount /dev/mapper/void-var /mnt/var
    mount /dev/nvme0n1p2 /mnt/boot
    mount /dev/nvme0n1p1 /mnt/boot/efi
    for fs in dev proc sys; do
      mount -o bind /${fs} /mnt/${fs}
    done
}

copykey
setupgpg
decryptluks
mountfs
