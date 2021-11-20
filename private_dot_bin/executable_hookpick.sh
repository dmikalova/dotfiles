#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

# https://github.com/jaxxstorm/Hookpick
# vault operator init -key-shares 1 -key-threshold 1
echo "Starting $(basename "${0}")"
CONFIG="${HOME}/.config/hookpick/config.hcl"
export VAULT_SKIP_VERIFY="true"

finish() {
    pkill -f "cddc39-port-forward.sh" || true
    pkill -f "ssh -N -L" || true
}
trap finish EXIT
finish

echo "Hookpick unseal 0"
cddc39-port-forward.sh 0 &
sleep 5
hookpick --config "${CONFIG}" unseal
finish

echo "Hookpick unseal 1"
cddc39-port-forward.sh 1 &
sleep 5
hookpick --config "${CONFIG}" unseal
finish

echo "Hookpick unseal 2"
cddc39-port-forward.sh 2 &
sleep 5
hookpick --config "${CONFIG}" unseal
finish

echo "Finished $(basename "${0}")"
