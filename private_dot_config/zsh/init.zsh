#!/bin/zsh

DIR="$(dirname "${0}")"

# start prompt
source "${DIR}/prompt-start.zsh"

# source configs
source "${DIR}/aliases.zsh"
source "${DIR}/exports.zsh"
source "${DIR}/functions.zsh"
source "${DIR}/load.zsh"
source "${DIR}/plugins.zsh"
source "${DIR}/settings.zsh"

# end prompt
source "${DIR}/prompt-end.zsh"

unset DIR
