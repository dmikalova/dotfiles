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
