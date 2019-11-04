#!/bin/bash
set -euxo pipefail

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
