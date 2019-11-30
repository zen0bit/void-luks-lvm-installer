#!/bin/bash

xbps-install -Sy go || true

su -w GOPATH,GOTMPDIR -s /bin/bash -c '
declare -n godir
for godir in ${!GO*}; do
    mkdir -p "$godir"
done

go get -u \
  github.com/go-delve/delve/cmd/dlv \
  github.com/golangci/golangci-lint/cmd/golangci-lint \
  golang.org/x/lint/golint \
  golang.org/x/tools/cmd/goimports \
  golang.org/x/tools/cmd/gorename \
  golang.org/x/tools/cmd/guru \
  gotest.tools/gotestsum
' - "${USERACCT-root}"
