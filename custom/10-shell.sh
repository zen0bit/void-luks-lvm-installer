#!/bin/bash

xbps-install -Sy zsh exa fzf || true

chsh -s /bin/zsh ivan
