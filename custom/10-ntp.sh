#!/bin/bash

xbps-install -Sy chrony || true

# Enable service
ln -sfn /etc/sv/chronyd /etc/runit/runsvdir/default/
