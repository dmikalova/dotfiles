#!/bin/sh
# `set -e` interferes with `crontab -r` with `crontab -l`
set -u
if [ "${DEBUG:=}" = true ]; then set -x; fi

crontab -r

(
    crontab -l 2>/dev/null
    echo "* 10 * * * ${HOME}/.bin/cron-sleep-lock.sh"
    echo "30,35,40,45,50,55 22 * * * ${HOME}/.bin/cron-sleep-notification.sh"
    echo "*/5 23 * * * ${HOME}/.bin/cron-sleep-notification.sh"
    echo "*/5 23 * * * ${HOME}/.bin/cron-sleep-pause-music.sh"
    echo "*/5 23 * * * ${HOME}/.bin/cron-sleep-lock.sh"

    # Get cron env:
    # echo "* * * * * /usr/bin/env > ${HOME}/cron-env"
    # Run tests with cron env:
    # /usr/bin/env -i "$(cat ${HOME}/cron-env)" "$@"
) | crontab -
