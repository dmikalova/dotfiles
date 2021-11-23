#!/bin/zsh

autoload -Uz compinit
compinit -d "${DIR}/cache/zcompdump"

if hash doctl 2>/dev/null; then
  doctl completion zsh | dd status=none of="${HOME}/.config/zsh/completions/_doctl"
fi

if hash gh 2>/dev/null; then
  gh completion -s zsh | dd status=none of="${HOME}/.config/zsh/completions/_gh"
fi

if hash helm 2>/dev/null; then
  helm completion zsh | dd status=none of="${HOME}/.config/zsh/completions/_helm"
fi

if hash kubectl 2>/dev/null; then
  kubectl completion zsh | dd status=none of="${HOME}/.config/zsh/completions/_kubectl"
fi

# if hash terraform 2>/dev/null; then
#   autoload -U +X bashcompinit && bashcompinit
#   complete -o nospace -C "$(which terraform)" terraform
# fi

# if hash vault 2>/dev/null; then
#   complete -o nospace -C "/snap/vault/current/bin/vault" vault
# fi
