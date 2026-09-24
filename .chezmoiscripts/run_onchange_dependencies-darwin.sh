#!/bin/sh
# macOS dependencies installed via Homebrew

echo "installing brew packages"
brew install \
	"age" \
	"antidote" \
	"atuin" \
	"aws-sso-util" \
	"aws-vpn-client" \
	"awscli" \
	"awsume" \
	"bat" \
	"carapace" \
	"catimg" \
	"chezmoi" \
	"chroma" \
	"circleci" \
	"claude-code" \
	"cloc" \
	"colordiff" \
	"coreutils" \
	"deno" \
	"difftastic" \
	"direnv" \
	"eza" \
	"fd" \
	"fzf" \
	"gh" \
	"ghostty" \
	"git" \
	"git-delta" \
	"gnupg" \
	"golang" \
	"hunk" \
	"jq" \
	"jqp" \
	"moor" \
	"meetingbar" \
	"nvm" \
	"opentofu" \
	"ouch" \
	"pinentry-mac" \
	"postgresql@15" \
	"ripgrep" \
	"shellcheck" \
	"shfmt" \
	"sops" \
	"starship" \
	"zoxide"

brew install --cask \
	"bitwarden" \
	"discord" \
	"docker-desktop" \
	"font-sauce-code-pro-nerd-font" \
	"hammerspoon" \
	"linearmouse" \
	"obsidian" \
	"signal" \
	"visual-studio-code"

echo "installing node via nvm"
export NVM_DIR="${HOME}/.nvm"
mkdir -p "${NVM_DIR}"
# shellcheck disable=SC1091
. "/opt/homebrew/opt/nvm/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
corepack enable
