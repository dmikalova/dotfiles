#!/bin/zsh

# nvm: node/npm from the newest installed version are on PATH right away; nvm
# itself (~230ms to load) is sourced on first use.
node_dir=("${NVM_DIR}"/versions/node/*(N/nOn[1]))
path=(${node_dir:+${node_dir}/bin} $path)
unset node_dir
nvm() {
	unfunction nvm
	source "/opt/homebrew/opt/nvm/nvm.sh"
	nvm "$@"
}

# starship
_cached_init starship "starship init zsh"

# zoxide
_cached_init zoxide "zoxide init zsh"

# z: zoxide's keyword match first, then fall back to a fuzzy match over the
# frecency list (in frecency order), so `z gooiogoo` finds goodship-io/goodship.
z() {
	if (($# == 0)) || [[ $# -eq 1 && ($1 == - || -d $1) ]]; then
		__zoxide_z "$@"
		return
	fi
	local result
	result="$(zoxide query -- "$@" 2>/dev/null)" ||
		result="$(zoxide query --list | fzf --filter="$*" --scheme=path --tiebreak=index | head -1)"
	if [[ -z $result ]]; then
		echo "z: no match for '$*'" >&2
		return 1
	fi
	# Unlike zoxide's z, stay put when already in the best match.
	[[ $result == "$(__zoxide_pwd)" ]] || __zoxide_cd "${result}"
}

# fzf: Ctrl+T files, Alt+C directories. Only the key bindings - fzf's own
# completion would take over Tab, which belongs to fzf-tab.
source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

# atuin: Ctrl+R history search (replaces fzf's). ↑/↓ stay with
# history-substring-search.
_cached_init atuin "atuin init zsh --disable-up-arrow"
ZSH_AUTOSUGGEST_STRATEGY=(history completion) # atuin prepends its own strategy

# pay-respects: `fuck` fixes the last command. --nocnf keeps Homebrew's
# command-not-found handler.
_cached_init pay-respects "pay-respects zsh --alias fuck --nocnf"
