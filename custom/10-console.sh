#!/bin/bash

xbps-install -Sy rxvt-unicode terminus-font tmux || true

echo 'FONT=ter-128b' >> /etc/rc.conf
