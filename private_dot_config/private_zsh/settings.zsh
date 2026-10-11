#!/bin/zsh

# history
HISTFILE="${DIR}/cache/history" # ZSH history file location.
HISTSIZE=100000                 # Maximum number of lines in zsh history before deduping.
SAVEHIST=100000                 # Maximum number of lines in zsh history.

setopt APPEND_HISTORY       # Append rather than copy on save.
setopt HIST_IGNORE_ALL_DUPS # Ignore duplicates.
setopt HIST_IGNORE_SPACE    # Ignore commands starting with a space.
setopt HIST_REDUCE_BLANKS   # Remove extra whitespace.
setopt SHARE_HISTORY        # Share history between shells.

# autocompletion
setopt AUTO_CD          # Automatically cd if possible.
setopt ALWAYS_TO_END    # Autocomplete within a word moves to the end of the word.
setopt COMPLETE_ALIASES # Autocomplete aliases.
setopt COMPLETE_IN_WORD # In word completion.
setopt REC_EXACT        # Recognize exact ambiguous matches.

zstyle ':completion:*' menu no                    # fzf-tab replaces the menu.
zstyle ':completion:*:descriptions' format '[%d]' # Group headers in fzf-tab.
zstyle ':completion:*' list-colors ''             # Colorize completion menu.
zstyle ':completion:*' rehash true                # Rehash PATH cache automatically.
# Case-insensitive, then partial words (f-b -> foo-bar), then substring.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# fzf-tab: same look as Ctrl+R/Ctrl+T, < and > switch completion groups,
# preview directory contents when completing cd/z.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'eza -1 --color=always $realpath'

# text navigation - use cat and press key combo to get code
bindkey '^[[1;5D' backward-word # cmd + ←
bindkey '^[[1;5C' forward-word  # cmd + →
bindkey '^[[H' beginning-of-line # home
bindkey '^[[F' end-of-line       # end
bindkey '^H' backward-kill-word # cmd + ⌫
bindkey '^[[3;5~' kill-word     # cmd + ⌦
# bindkey '[I' backward-kill-line # cmd + ⌫

# Word motions and deletes stop at punctuation like / - . = as in text editors;
# only letters, digits and _ count as part of a word.
WORDCHARS='_'

# undo / redo line edits: Ghostty sends these for Cmd+Z / Cmd+Shift+Z
bindkey '^_' undo
bindkey '^[[122;10u' redo

# miscellaneous settings.
bindkey "\e[3~" delete-char # ⌦

unsetopt FLOW_CONTROL # Ctrl+S/Ctrl+Q don't freeze/unfreeze the terminal.
setopt NO_BEEP        # Disable system beep.

# Charm/termenv tools (terramate) ask the terminal for its background color
# with OSC 11 + a cursor position report. Run as a child that doesn't own the
# tty - a lefthook job - they never read the answer, so the terminal echoes it
# and leaves it in the input queue, where zle self-inserts it into the next
# command line. Drop a pending reply, but hand back anything typed ahead.
_discard_terminal_replies() {
	local char kind
	while read -u 0 -t 0 -s -k 1 char; do
		if [[ $char != $'\e' ]]; then
			print -z -- "$char"
			return
		fi
		read -u 0 -t 0.05 -s -k 1 kind || return
		case $kind in
		# OSC, ends with BEL or ESC \.
		']')
			while read -u 0 -t 0.05 -s -k 1 char; do
				[[ $char == $'\a' ]] && break
				[[ $char == $'\e' ]] && { read -u 0 -t 0.05 -s -k 1 char; break; }
			done
			;;
		# CSI, ends with a byte in @-~.
		'[')
			while read -u 0 -t 0.05 -s -k 1 char; do
				[[ $char == [@-~] ]] && break
			done
			;;
		esac
	done
}
precmd_functions+=(_discard_terminal_replies)

# Turn off autocorrection
unsetopt correct_all
