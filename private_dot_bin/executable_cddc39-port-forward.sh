#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
INSTANCE="${1:-0}"
ADDRESS="ssh${INSTANCE}.cddc39.tech"
KNOWN_HOSTS="${HOME}/.ssh/known_hosts"

# 2015
# 4646 Nomad
# 8080 Consul
# 8200 Vault
# 9000 Traefik
# 9001 Traefik UI

ssh-keygen -f "${KNOWN_HOSTS}" -R "${ADDRESS}"
ssh-keyscan "${ADDRESS}" >>"${KNOWN_HOSTS}"

ssh -N \
    -L "2015:127.0.0.1:2015" \
    -L "4646:127.0.0.1:4646" \
    -L "8080:127.0.0.1:8080" \
    -L "8200:127.0.0.1:8200" \
    -L "8500:127.0.0.1:8500" \
    -L "9000:127.0.0.1:9000" \
    -L "9001:127.0.0.1:9001" \
    "root@${ADDRESS}"

echo "Finished $(basename "${0}")"
