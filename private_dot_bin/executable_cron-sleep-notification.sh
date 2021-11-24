#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

export "$(grep -Ez DBUS_SESSION_BUS_ADDRESS /proc/"$(pgrep -u "dmikalova" "plasma" | head -n 1)"/environ)"

for _ in $(seq 10); do
    /usr/bin/notify-send -a "David..." -t 60000 "it is time to go to sleep"
    sleep 12
done

echo "Finished $(basename "${0}")"
