#!/bin/sh
# Stop AI agents from adding themselves to commits and PRs. Each app also
# writes its own settings file, so this merges single keys into the file
# rather than letting chezmoi own it.

set -eu

# Plain JSON files: merge with jq.
merge() {
  file=$1
  filter=$2
  mkdir -p "$(dirname "${file}")"
  [ -s "${file}" ] || echo '{}' >"${file}"
  tmp=$(mktemp)
  jq "${filter}" "${file}" >"${tmp}"
  mv "${tmp}" "${file}"
}

# Copilot CLI, and the Copilot SDK agent in VS Code.
merge "${HOME}/.copilot/settings.json" '.includeCoAuthoredBy = false'

# Claude Code. Empty strings remove the attribution text.
merge "${HOME}/.claude/settings.json" '.attribution.commit = "" | .attribution.pr = ""'

# VS Code. settings.json is JSONC, with comments and trailing commas, which
# jq cannot read. Edit the one key as text.
case "$(uname -s)" in
Darwin) vscode="${HOME}/Library/Application Support/Code/User/settings.json" ;;
*) vscode="${HOME}/.config/Code/User/settings.json" ;;
esac
if [ ! -s "${vscode}" ]; then
  mkdir -p "$(dirname "${vscode}")"
  printf '{\n  "git.addAICoAuthor": "off"\n}\n' >"${vscode}"
elif grep -q '"git\.addAICoAuthor"' "${vscode}"; then
  perl -pi -e 's/("git\.addAICoAuthor"\s*:\s*)"[^"]*"/$1"off"/' "${vscode}"
else
  perl -0pi -e 's/\A(\s*\{)/$1\n  "git.addAICoAuthor": "off",/' "${vscode}"
fi
