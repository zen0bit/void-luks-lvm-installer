#!/bin/bash

xbps-install -Sy terminus-font tmux

echo 'FONT=ter-128b' >> /mnt/etc/rc.conf
