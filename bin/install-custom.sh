#!/bin/bash
set -euxo pipefail

# Custom setup of rest of the system

tmpenc=$(mktemp)
cleanup() {
    rm -f "$tmpenc"
    rm -rf /mnt/tmp/custom
}

trap cleanup INT TERM

PUBKEY="$PWD/custom/files/pubkey.gpg"
if [ -r "$PUBKEY" ]; then
    export GNUPGHOME=/root/.gnupg
    # Import the main GPG identity for the account
    gpg2 --import "$PUBKEY"

    # Bind mount the GnuPG socket directory inside the chroot to make GnuPG and SSH
    # auth work during the custom setup phase.
    mkdir -p "/mnt$GNUPGHOME" && chmod 700 $_
    mount -o bind "$GNUPGHOME" "/mnt$GNUPGHOME"

    # Unlock smartcard
    gpg2 --card-status
    GPGID=$(gpg2 --with-colons --fingerprint | awk -F: '$1 == "fpr" {print $10;}' | head -1)
    echo | gpg2 --always-trust -r "$GPGID" --encrypt > "$tmpenc" && gpg2 -d "$tmpenc"
fi

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
fi

cleanup
