#!/bin/sh
# macOS dependencies installed via Homebrew

echo "installing brew packages"
brew install \
	"age" \
	"aws-sso-util" \
	"aws-vpn-client" \
	"awscli" \
	"awsume" \
	"catimg" \
	"chezmoi" \
	"chroma" \
	"circleci" \
	"claude-code" \
	"cloc" \
	"colordiff" \
	"coreutils" \
	"deno" \
	"direnv" \
	"eza" \
	"fd" \
	"fzf" \
	"gh" \
	"ghostty" \
	"git" \
	"gnupg" \
	"golang" \
	"jq" \
	"meetingbar" \
	"nvm" \
	"opentofu" \
	"postgresql@15" \
	"pinentry-mac" \
	"ripgrep" \
	"shellcheck" \
	"shfmt" \
	"sops" \
	"starship" \
	"thefuck" \
	"trash-cli" \
	"zoxide" \
	"zsh-autosuggestions"

brew install --cask \
	"bitwarden" \
	"discord" \
	"docker-desktop" \
	"font-jetbrains-mono-nerd-font" \
	"hammerspoon" \
	"linearmouse" \
	"visual-studio-code"

echo "installing node via nvm"
export NVM_DIR="${HOME}/.nvm"
mkdir -p "${NVM_DIR}"
# shellcheck disable=SC1091
. "/opt/homebrew/opt/nvm/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
corepack enable
