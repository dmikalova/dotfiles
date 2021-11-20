#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

DIR="$(git rev-parse --show-toplevel || true)"
if [ "${DIR}" = "$HOME/code/github.com/dmikalova/infrastructure" ]; then
    CREDS=$(sops -d "${DIR}/digitalocean/digitalocean.sops.json")
    AWS_ACCESS_KEY_ID="$(echo "${CREDS}" | jq -r ".DIGITALOCEAN_SPACES_KEY")"
    AWS_SECRET_ACCESS_KEY="$(echo "${CREDS}" | jq -r ".DIGITALOCEAN_SPACES_SECRET")"
fi

FILE="./terragrunt.hcl"
if test -f "$FILE"; then
    SOURCE=$(hcledit attribute get terraform.source -f "${FILE}")
    SOURCE_DIR=$(echo "$SOURCE" | sed -E 's/.*:(.*)\.git.*/\1/')
    MODULE_DIR=$(echo "$SOURCE" | sed -E 's/.*\.git(.*)"/\1/')
    TERRAGRUNT_SOURCE="$HOME/code/github.com/${SOURCE_DIR}${MODULE_DIR}"
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export TERRAGRUNT_INCLUDE_EXTERNAL_DEPENDENCIES=true
export TERRAGRUNT_SOURCE

terragrunt "$@"
