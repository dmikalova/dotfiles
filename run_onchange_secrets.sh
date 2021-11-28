#!/bin/sh
set -eu

cleanup() {
    rm -rf "${TMP_DIR}"
}
TMP_DIR="${HOME}/bw-tmp"
mkdir --parents "${TMP_DIR}"
trap cleanup EXIT

echo "Unlocking bitwarden"
BW_SESSION="$(bw unlock --raw)"
export BW_SESSION

BW_ID_SSH=$(bw get item "ssh key home-desktop" | jq -r .id)
bw get attachment "id_home-desktop" --itemid "${BW_ID_SSH}" --output "${TMP_DIR}/"
bw get attachment "id_home-desktop.pub" --itemid "${BW_ID_SSH}" --output "${TMP_DIR}/"
SSH_DIR="${HOME}/.ssh"
mv -v "${TMP_DIR}/"* "${SSH_DIR}"
chmod 600 "${SSH_DIR}/"*

BW_ID_SOPS=$(bw get item "sops age key" | jq -r .id)
bw get attachment "keys.txt" --itemid "${BW_ID_SOPS}" --output "${TMP_DIR}/"
SOPS_AGE_DIR="${HOME}/.config/sops/age"
mkdir --parents "${SOPS_AGE_DIR}"
mv -v "${TMP_DIR}/"* "${SOPS_AGE_DIR}"
chmod 600 "${SOPS_AGE_DIR}/"*

BW_ID_SOPS=$(bw get item "gpg key" | jq -r .id)
bw get attachment "private.key" --itemid "${BW_ID_SOPS}" --output "${TMP_DIR}/"
bw get attachment "trustlevel.txt" --itemid "${BW_ID_SOPS}" --output "${TMP_DIR}/"
gpg --import "${TMP_DIR}/private.key"
gpg --import-ownertrust "${TMP_DIR}/trustlevel.txt"
rm "${TMP_DIR}/"*
