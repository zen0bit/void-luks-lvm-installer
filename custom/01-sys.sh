#!/bin/bash

xbps-install -Sy \
  acpi base-devel cmake curl dbus git htop liblz4 lm_sensors ntfs-3g readline \
  rsync strace xtools wget xz || true

xbps-install -Sy go || true
su -w GOPATH,GOTMPDIR -s /bin/bash -c '
declare -n godir
for godir in ${!GO*}; do
    mkdir -p "$godir"
done

go get -u github.com/imiric/scron
' - "${USERACCT-root}"
