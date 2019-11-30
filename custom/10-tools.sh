#!/bin/bash

xbps-install -Sy dtrx lf pandoc par2cmdline parted pass pass-otp pixz p7zip \
  ripgrep translate-shell unrar words-mnemonic zip || true

xbps-install -Sy go || true
su -w GOPATH,GOTMPDIR -s /bin/bash -c '
declare -n godir
for godir in ${!GO*}; do
    mkdir -p "$godir"
done

go get -u \
  github.com/imiric/tarsplitter
' - "${USERACCT-root}"
