#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

DIR="${HOME}/code/github.com"

cd "${DIR}"
terragrunt-delete-caches.sh
trap terragrunt-delete-caches.sh EXIT
TF_DIRS=$(find "dmikalova" "e91e63" "cddc39" "screeptorio" -name "main.tf" | sed -n -r 's/main.tf//p')
echo "$TF_DIRS"
echo "${TF_DIRS}" | while read -r TF_DIR; do
    echo "${TF_DIR}"
    cd "${DIR}/${TF_DIR}"
    terraform init
    rm .terraform.lock.hcl
    tflint --config "${HOME}/.config/tflint/config.hcl"
done
cd "${DIR}"
