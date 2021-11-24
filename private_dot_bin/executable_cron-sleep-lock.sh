#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

export "$(grep -Ez DBUS_SESSION_BUS_ADDRESS /proc/"$(pgrep -u "dmikalova" "plasma" | head -n 1)"/environ)"
loginctl lock-session

echo "Finished $(basename "${0}")"
