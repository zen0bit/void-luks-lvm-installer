#!/bin/bash

xbps-install -Sy exa fd fzf moreutils zsh || true

chsh -s /bin/zsh ivan
