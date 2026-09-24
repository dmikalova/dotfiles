#!/bin/zsh

# Emacs-style line editing. Must be selected before plugins bind keys: EDITOR=vim
# makes zsh start in vi mode, and switching later would drop their bindings.
bindkey -e

# zsh-autosuggestions: most recent matching command, else what Tab would
# complete. Set before loading; atuin's strategy isn't used.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1

# antidote: plugins listed in plugins.txt, compiled to a static file that is
# only regenerated when plugins.txt changes. Update with `antidote update`.
source "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
antidote load "${DIR}/plugins.txt" "${ZSH_CACHE_DIR}/plugins.zsh"

# history-substring-search doesn't bind keys. Bind both arrow encodings:
# normal mode (^[[A, what Ghostty sends at the prompt) and application mode (^[OA).
for KEYMAP_NAME in emacs viins; do
	bindkey -M "${KEYMAP_NAME}" '^[[A' history-substring-search-up
	bindkey -M "${KEYMAP_NAME}" '^[OA' history-substring-search-up
	bindkey -M "${KEYMAP_NAME}" '^[[B' history-substring-search-down
	bindkey -M "${KEYMAP_NAME}" '^[OB' history-substring-search-down
done
unset KEYMAP_NAME
