#!/bin/bash

# Install curl for alpine_base.sh
xbps-install -yS curl

# Runs base image creation scripts
# After reboot the resulting tarballs can be imported
cd /srv/docker/images/alpinelinux/alpine_base
./alpine_base.sh

cd /srv/docker/images/voidlinux/void_base
./void_base.sh

# Remove curl
xbps-remove -yR curl
