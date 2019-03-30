#!/bin/bash

xbps-install -Sy bluez obexfs || true

if [ -n "$USERACCT" ]; then
  usermod -aG bluetooth ${USERACCT}
fi
