#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

bin() {
    NAME="$1"
    URL="$2"

    wget -q -O "${HOME}/.local/bin/${NAME}" "${URL}"
    chmod +x "${HOME}/.local/bin/${NAME}"
}

targz() {
    NAME="$1"
    URL="$2"
    COUNT="$(echo "${NAME}" | tr -cd '/' | wc -c)"

    wget -qO- "${URL}" | tar xz --directory "${HOME}/.local/bin" "${NAME}" --strip-components "${COUNT}"
    chmod +x "${HOME}/.local/bin/$(basename "${NAME}")"
}

tarxz() {
    NAME="$1"
    URL="$2"
    COUNT="$(echo "${NAME}" | tr -cd '/' | wc -c)"

    wget -qO- "${URL}" | tar xJ --directory "${HOME}/.local/bin" "${NAME}" --strip-components "${COUNT}"
    chmod +x "${HOME}/.local/bin/$(basename "${NAME}")"
}

zip() {
    NAME="$1"
    URL="$2"

    wget -qO- "${URL}" | zcat >"${HOME}/.local/bin/${NAME}"
    chmod +x "${HOME}/.local/bin/${NAME}"
}

targz "age/age" "https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz"
targz "age/age-keygen" "https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz"
bin "bitwarden" "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=appimage"
zip "bw" "https://vault.bitwarden.com/download/?app=cli&platform=linux"
targz "chezmoi" "https://github.com/twpayne/chezmoi/releases/download/v2.9.0/chezmoi_2.9.0_linux_amd64.tar.gz"
bin "chrysalis" "https://github.com/keyboardio/Chrysalis/releases/download/v0.8.6/Chrysalis-0.8.6.AppImage"
targz "doctl" "https://github.com/digitalocean/doctl/releases/download/v1.67.0/doctl-1.67.0-linux-amd64.tar.gz"
targz "hcledit" "https://github.com/minamijoyo/hcledit/releases/download/v0.2.2/hcledit_0.2.2_linux_amd64.tar.gz"
tarxz "shellcheck-v0.8.0/shellcheck" "https://github.com/koalaman/shellcheck/releases/download/v0.8.0/shellcheck-v0.8.0.linux.x86_64.tar.xz"
bin "sops" "https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux"
zip "terraform" "https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip"
bin "terragrunt" "https://github.com/gruntwork-io/terragrunt/releases/download/v0.35.13/terragrunt_linux_amd64"
