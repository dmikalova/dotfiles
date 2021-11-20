#!/bin/sh

# Get env with this:
# * * * * *   /usr/bin/env > /home/dmikalova/..../cenv

# Run as env with this:
/usr/bin/env -i "$(cat ./cenv)" "$@"
