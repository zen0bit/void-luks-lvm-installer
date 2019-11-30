#!/bin/bash

REPOPATH="/home/${USERACCT}/.files"

# Copy the known_hosts for host verification
mkdir -m 700 -p "/home/${USERACCT}/.ssh"
cp /tmp/custom/files/known_hosts "/home/${USERACCT}/.ssh/"

test -d "$REPOPATH" || \
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/home/${USERACCT}/.ssh/known_hosts -o Hostname=172.16.1.5 -o Port=10022" \
SSH_AUTH_SOCK=/root/.gnupg/S.gpg-agent.ssh \
git clone git@git.imiric.lan:ivan/dotfiles.git "$REPOPATH" && \
git -C "$REPOPATH" submodule update --init

# Fix ownership
chown -R $USERACCT: /home/$USERACCT/{.files,.ssh}
