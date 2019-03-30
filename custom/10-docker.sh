#!/bin/bash

xbps-install -Sy docker docker-compose || true

# Enable service
ln -sfn /etc/sv/docker /etc/runit/runsvdir/default/
