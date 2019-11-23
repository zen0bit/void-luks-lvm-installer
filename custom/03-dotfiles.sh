#!/bin/bash

# Copy the known_hosts for host verification
mkdir -m 700 -p /home/ivan/.ssh
cp $(dirname "$0")/files/known_hosts /home/ivan/.ssh/

test -d /home/ivan/.files || \
GIT_SSH_COMMAND='ssh -o UserKnownHostsFile=/home/ivan/.ssh/known_hosts -o Hostname=172.16.1.5 -o Port=10022' \
SSH_AUTH_SOCK=/root/.gnupg/S.gpg-agent.ssh \
git clone git@git.imiric.lan:ivan/dotfiles.git /home/ivan/.files && \
chown -R ivan: /home/ivan/{.files,.ssh}
