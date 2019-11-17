#!/bin/bash

xbps-install -Sy gnupg2 gnupg2-scdaemon pcsclite pcsc-ccid || true

# Enable pcscd service for smartcard access
ln -sfn /etc/sv/pcscd /etc/runit/runsvdir/default/

tmpenc=$(mktemp)
cleanup() {
    rm -f "$tmpenc"
}

trap cleanup INT TERM

PUBKEY="/tmp/custom/files/pubkey.gpg"

if [ -r "$PUBKEY" ]; then
    if [ -n "$USERACCT" ]; then
        gpghome="/home/$USERACCT/.gnupg"
    else
        gpghome="/root/.gnupg"
    fi

    export GNUPGHOME="$gpghome"
    # Import the main GPG identity for the account
    su - "${USERACCT-root}" -c "gpg2 --import $PUBKEY"

    # Unlock smartcard
    gpg2 --card-status
    GPGID=$(gpg2 --with-colons --fingerprint | awk -F: '$1 == "fpr" {print $10;}' | head -1)
    echo | gpg2 --always-trust -r "$GPGID" --encrypt > "$tmpenc" && gpg2 -d "$tmpenc"
fi

cleanup
