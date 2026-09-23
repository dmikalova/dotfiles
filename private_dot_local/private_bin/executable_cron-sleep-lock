#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

SESSIONS="$(loginctl show-user "$LOGNAME" -p "Sessions" --value)"
for SESSION in $SESSIONS; do
    loginctl lock-session "${SESSION}"
done

echo "Finished $(basename "${0}")"
