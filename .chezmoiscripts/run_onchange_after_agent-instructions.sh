#!/bin/sh
# Link each agent's global instructions file to ~/.agents/AGENTS.md. Done here
# rather than as chezmoi targets so chezmoi doesn't manage ~/.claude. A real
# file already in place is left alone.

set -eu

for link in \
	"${HOME}/.claude/CLAUDE.md" \
	"${HOME}/.copilot/copilot-instructions.md" \
	"${HOME}/.github/copilot-instructions.md"; do
	if [ -e "${link}" ] && [ ! -L "${link}" ]; then
		echo "skipping ${link}: a real file is in the way" >&2
		continue
	fi
	mkdir -p "$(dirname "${link}")"
	ln -sfn "${HOME}/.agents/AGENTS.md" "${link}"
done
