#!/bin/bash

xbps-install -Sy bluez obexfs

if [ -n "$USERACCT" ]; then
  usermod -aG bluetooth ${USERACCT}
fi
