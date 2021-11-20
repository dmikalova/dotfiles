#!/bin/zsh

# history
HISTFILE="${DIR}/cache/history" # ZSH history file location.
HISTSIZE=100000                 # Maximum number of lines in zsh history before deduping.
SAVEHIST=100000                 # Maximum number of lines in zsh history.

bindkey '^r' history-incremental-search-backward # ctl + r allows history search.
bindkey '^[[A' up-line-or-search                 # Pressing up will filter history by current command.
bindkey '^[[B' down-line-or-search               # Pressing down will filter history by current command.

setopt APPEND_HISTORY       # Append rather than copy on save.
setopt HIST_IGNORE_ALL_DUPS # Ignore duplicates.
setopt HIST_IGNORE_SPACE    # Remove extra whitespace.
setopt HIST_REDUCE_BLANKS   # Ignore commands starting with a space.
setopt SHARE_HISTORY        # Share history between shells.

# autocompletion
setopt AUTO_CD          # Automatically cd if possible.
setopt ALWAYS_TO_END    # Autocomplete within a word moves to the end of the word.
setopt COMPLETE_ALIASES # Autocomplete aliases.
setopt COMPLETE_IN_WORD # In word completion.
setopt REC_EXACT        # Recognize exact ambiguous matches.

zstyle ':completion:*' menu select    # Autocomplete menu.
zstyle ':completion:*' list-colors '' # Colorize completion menu.
zstyle ':completion:*' rehash true    # Rehash PATH cache automatically.

# text navigation - use cat and press key combo to get code
bindkey '^[[1;5D' backward-word # cmd + ←
bindkey '^[[1;5C' forward-word  # cmd + →
bindkey '[[H' beginning-of-line # home
bindkey '[[F' end-of-line       # end
bindkey '^H' backward-kill-word # cmd + ⌫
bindkey '^[[3;5~' kill-word     # cmd + ⌦
# bindkey '[I' backward-kill-line # cmd + ⌫

# miscellaneous settings.
bindkey -v                  # Enable Vi mode.
bindkey ' ' magic-space     # Expand history commands with a space such as !!.
bindkey "\e[3~" delete-char # ⌦

setopt FLOW_CONTROL # Enable ctl + S and ctl + Q for flow control.
setopt NO_BEEP      # Disable system beep.

# Turn off autocorrection
unsetopt correct_all

# stty key mappings
[[ -n ${TTY:-} && $+commands[stty] == 1 ]] && stty intr ^J <$TTY >$TTY
# stty start ^O # start / ctrl+q
# stty stop ^I # stop / ctrl+s
