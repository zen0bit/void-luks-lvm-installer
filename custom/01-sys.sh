#!/bin/bash

xbps-install -Sy \
  acpi base-devel curl dbus git htop liblz4 lm_sensors readline rsync strace \
  xtools wget xz || true
