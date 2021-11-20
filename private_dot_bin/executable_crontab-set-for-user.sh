#!/bin/sh
set -u
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "Setting crontab"
# NB: `set -e` messes up `crontab -r` with `crontab -l`
crontab -r

(
    crontab -l 2>/dev/null
    echo "*    22-23 * * *  ${HOME}/.bin/sleep-notification.sh"
    echo "*    22-23 * * *  playerctl pause"
    echo "*/15 22-23 * * *  loginctl lock-session"
) | crontab -

echo "Finished $(basename "${0}")"
