#!/bin/bash

xbps-install -Sy \
  acpi base-devel dbus git htop lm_sensors readline rsync strace xtools xz \
  || true
