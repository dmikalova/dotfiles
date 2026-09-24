#!/bin/zsh

DIR="${HOME}/.config/zsh"

# A login shell is a terminal's top-level shell, so start the nesting count at 1.
# Ghostty inherits SHLVL=1 when launched from a shell (`open`), and its login
# wrapper then counts one level too many.
[[ -o login ]] && export SHLVL=1

# source configs
source "${DIR}/aliases.zsh"
source "${DIR}/exports.zsh"
source "${DIR}/functions.zsh"
source "${DIR}/plugins.zsh"
source "${DIR}/load.zsh"
source "${DIR}/settings.zsh"

unset DIR
