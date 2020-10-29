#!/bin/bash

# Install and enable service
cp -r /tmp/custom/files/runit/cache-tmpfs /etc/sv/
ln -sfn /etc/sv/cache-tmpfs /etc/runit/runsvdir/default/
