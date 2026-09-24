#!/bin/zsh
# Completion setup. Loaded from plugins.txt so it runs after plugins that add
# completion definitions to fpath (zsh-completions) and before fzf-tab.

# zsh completions: rebuild the dump when it's missing or a completion dir changed
# since it was written (a tool was installed or upgraded); otherwise load it
# without re-scanning (-C).
autoload -Uz compinit
dump="${ZSH_CACHE_DIR}/zcompdump"
changed=(${^fpath}(N-/e:'[[ $REPLY -nt $dump ]]':))
if [[ ! -s $dump ]] || ((${#changed})); then
	compinit -d "${dump}"
	touch "${dump}"
else
	compinit -C -d "${dump}"
fi
unset dump changed

# git: Homebrew's _git (first on fpath) wraps git's bash completion, which only
# offers --long flags without descriptions (and fails to find that script here).
# Load zsh's own _git now (+X). The stub compinit defines must go first -
# otherwise +X resolves the existing stub via fpath and gets Homebrew's again.
unfunction _git 2>/dev/null
autoload -Uz +X "/usr/share/zsh/${ZSH_VERSION}/functions/_git"

# carapace: completions for ~1000 more CLIs, registered only for commands zsh
# has no completion for, so native ones (like _git above) stay in charge.
_cached_init carapace "carapace _carapace zsh | sed '/^compdef _carapace_completer /{s//_carapace_commands=(/;s/\$/)/;}'"
_zsh_completed=(${(k)_comps})
compdef _carapace_completer ${_carapace_commands:|_zsh_completed}
unset _carapace_commands _zsh_completed

# Flags parsed from `<cmd> --help`, for tools that neither zsh nor carapace
# cover. Listed explicitly rather than applied to everything: _gnu_generic runs
# the command, and scripts like coprd would do real work instead of printing help.
compdef _gnu_generic awsume claude cloc difft shfmt
