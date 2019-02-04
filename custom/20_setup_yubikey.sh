#!/bin/bash

# Install YubiKey udev rule
mkdir -p /mnt/etc/udev/rules.d
cp /srv/extra/70-yubikey.conf /mnt/etc/udev/rules.d/
