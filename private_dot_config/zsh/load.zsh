#!/bin/zsh

# direnv
eval "$(direnv hook zsh)"

# gpg
gpgconf --launch gpg-agent
