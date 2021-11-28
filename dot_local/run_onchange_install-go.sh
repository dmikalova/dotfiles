#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

DIR="$(mktemp)"
TARGZ="go1.17.3.linux-amd64.tar.gz"
wget -q "https://go.dev/dl/${TARGZ}" -P "${DIR}/"
rm -rf "${HOME}/.local/go"
tar -C "${HOME}/.local" -xzf "${DIR}/${TARGZ}"
rm -rf "${DIR}"
