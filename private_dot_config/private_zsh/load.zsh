#!/bin/zsh

# gpg
gpgconf --launch gpg-agent

# nvm
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# starship
eval "$(starship init zsh)"

# the fuck
eval $(thefuck --alias)

# zsh completions
autoload -Uz compinit
dump="${DIR}/cache/zcompdump"
if ( setopt extendedglob; [[ -n ${dump}(#qN.mh+24) ]] ); then
	compinit -d "${dump}"
else
	compinit -C -d "${dump}"
fi

# zoxide
eval "$(zoxide init zsh)"

# zsh-autosuggestions
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
