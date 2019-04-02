#!/bin/bash

xbps-install -Sy \
  acpi base-devel dbus git htop liblz4 lm_sensors readline rsync strace xtools xz \
  || true
