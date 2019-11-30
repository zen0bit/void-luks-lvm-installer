#!/bin/bash

xbps-install -Sy android-tools emacs-gtk3 jq qemu vim || true


if [ -n "$USERACCT" ]; then
  # For qemu
  usermod -aG kvm ${USERACCT}
  su - ${USERACCT} bash -c '
mkdir -p ~/src
test -d ~/src/diff-so-fancy || git clone https://github.com/so-fancy/diff-so-fancy.git ~/src/diff-so-fancy
mkdir -p ~/.local/bin && ln -sfn ~/src/diff-so-fancy/diff-so-fancy ~/.local/bin/
'
fi
