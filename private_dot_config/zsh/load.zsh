#!/bin/zsh

# gpg
gpgconf --launch gpg-agent

# starship
eval "$(starship init zsh)"

# the fuck
eval $(thefuck --alias)

# zsh completions
autoload -Uz compinit
compinit -d "${DIR}/cache/zcompdump"

# zoxide
eval "$(zoxide init zsh)"
