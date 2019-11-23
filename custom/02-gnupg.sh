#!/bin/bash

xbps-install -Sy gnupg2 gnupg2-scdaemon pcsclite pcsc-ccid || true

# Enable pcscd service for smartcard access
ln -sfn /etc/sv/pcscd /etc/runit/runsvdir/default/
