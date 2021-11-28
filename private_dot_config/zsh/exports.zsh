append_path() {
    local DIR="$1"

    if [ ! -d "${DIR}" ]; then
        return
    fi

    PATH="${PATH//":${DIR}"/}"
    export PATH="${PATH:+${PATH}:}${DIR}"
}

# bin
export BIN_DIR="${HOME}/.local/bin"
append_path "${BIN_DIR}"

# android
export ANDROID_SDK="${HOME}/Android/Sdk"
append_path "${ANDROID_SDK}/platform-tools"

# git
export GIT_CONFIG="${HOME}/.config/git/config"

# go
append_path "${HOME}/.local/go/bin"
export GOPATH="${HOME}/.cache/go-path"
append_path "${GOPATH}/bin"

# gpg
export GPG_TTY=$(tty)

# gtk
export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libgtk3-nocsd.so.0"

# locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# npm
NPM_CACHE_DIR="${HOME}/.cache/npm"
append_path "${NPM_CACHE_DIR}/bin"
export N_PREFIX="${NPM_CACHE_DIR}"
export NPM_CONFIG_USERCONFIG="${HOME}/.config/npm/npmrc"

# restic
export RESTIC_PASSWORD=""
export RESTIC_REPOSITORY="s3:https://nyc3.digitaloceanspaces.com/cddc39/backups"
export RESTIC_S3_ID="${DIGITALOCEAN_SPACES_ACCESS_KEY_CDDC39}"
export RESTIC_S3_KEY="${DIGITALOCEAN_SPACES_SECRET_KEY_CDDC39}"

# sops
export SOPS_AGE_RECIPIENTS="age1ahclcge5vrwwsc6nsud3t4h2mpx4e8ad3ta6aaxu4k87yeqc6vaqdxtpkx"

# steam
export STEAM_API_KEY=""

# terraform
export TF_CLI_CONFIG_FILE="${HOME}/.config/terraform/terraformrc"

# vim
export EDITOR="vim"

# zsh
export ZSH_COMPLETIONS_DIR="${DIR}/completions"
export ZSH_CACHE_DIR="${DIR}/cache"
export _Z_DATA="${ZSH_CACHE_DIR}/z_data"
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export ZSH_COLORIZE_TOOL=chroma
export FPATH="$FPATH:${ZSH_COMPLETIONS_DIR}"

unfunction append_path
