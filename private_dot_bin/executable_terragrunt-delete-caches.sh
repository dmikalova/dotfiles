#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Clearing .terraform caches"
find "${HOME}/code/github.com" -type d -name '.terraform' -exec rm -rf {} +

echo "Clearing .terragrunt-cache caches"
find "${HOME}/code/github.com" -type d -name '.terragrunt-cache' -exec rm -rf {} +
