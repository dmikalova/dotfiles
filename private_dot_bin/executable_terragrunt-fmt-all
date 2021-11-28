#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

OWNERS="cddc39 dmikalova e91e63 screeptorio"
ROOT_DIR="$HOME/code/github.com/"

for OWNER in $OWNERS; do
    DIR="${ROOT_DIR}/${OWNER}"
    terraform fmt --recursive "${DIR}"
    terragrunt hclfmt --terragrunt-working-dir "${DIR}"
done
