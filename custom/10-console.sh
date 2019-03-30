#!/bin/bash

xbps-install -Sy terminus-font tmux || true

echo 'FONT=ter-128b' >> /etc/rc.conf
