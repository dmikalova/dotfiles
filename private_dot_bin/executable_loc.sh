#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

cd "${HOME}/code/github.com"
cloc "cddc39" "dmikalova" "e91e63" "screeptorio" \
    --fullpath \
    --exclude-ext "nix,svg,vim" \
    --not-match-d '(.terragrunt-cache|build|dist|node_modules)' \
    --not-match-f '(.terraform.lock.hcl|package.lock.json)'
