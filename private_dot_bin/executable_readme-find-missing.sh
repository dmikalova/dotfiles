#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

MAINS=$(find . -name main.tf)
for MAIN in $MAINS; do
    DIR=$(dirname "${MAIN}")
    README="${DIR}/README.md"
    if ! test -f "${README}"; then
        echo "${README}"
        code "${README}"
        exit
    fi
done
