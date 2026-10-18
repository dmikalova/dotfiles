#!/bin/sh
# macOS dependencies installed via Homebrew

# `brew install` upgrades a package that is already present but outdated, which
# restarts apps like VS Code in the middle of whatever they were doing. `brew
# bundle --no-upgrade` installs only what is missing and leaves the rest alone.
# Upgrades are a separate, deliberate `brew upgrade`.
echo "installing brew packages"
brew bundle install --no-upgrade --file=- <<-'BREWFILE'
	brew "age"
	brew "antidote"
	brew "atuin"
	brew "aws-sso-util"
	brew "awscli"
	brew "awsume"
	brew "bat"
	brew "carapace"
	brew "catimg"
	brew "chezmoi"
	brew "chroma"
	brew "circleci"
	brew "cloc"
	brew "colordiff"
	brew "coreutils"
	brew "deno"
	brew "difftastic"
	brew "direnv"
	brew "docker"
	brew "eza"
	brew "fd"
	brew "ffmpeg"
	brew "fzf"
	brew "gh"
	brew "git"
	brew "git-delta"
	brew "gnupg"
	brew "go"
	brew "govulncheck"
	brew "gum"
	brew "hunk"
	brew "jj"
	brew "jq"
	brew "jqp"
	brew "lefthook"
	brew "mage"
	brew "moor"
	brew "neovim"
	brew "nmap"
	brew "nvm"
	brew "opentofu"
	brew "ouch"
	brew "pinentry-mac"
	brew "postgresql@15"
	brew "pulumi"
	brew "ripgrep"
	brew "shellcheck"
	brew "shfmt"
	brew "sops"
	brew "starship"
	brew "terramate"
	brew "tree-sitter-cli"
	brew "uv"
	brew "xorriso"
	brew "zellij"
	brew "zoxide"

	cask "aws-vpn-client"
	cask "bitwarden"
	cask "claude-code"
	cask "discord"
	cask "docker-desktop"
	cask "font-sauce-code-pro-nerd-font"
	cask "gcloud-cli"
	cask "ghostty"
	cask "hammerspoon"
	cask "linearmouse"
	cask "logitune"
	cask "meetingbar"
	cask "notion"
	cask "obsidian"
	cask "signal"
	cask "slack"
	cask "tailscale-app"
	cask "visual-studio-code"
	cask "zoom"
BREWFILE

# The shared checks from project-standards, run by lefthook in projects
# without go.mod. Rerun `go install ...@latest` to update it.
echo "installing project-standards"
GOBIN="${HOME}/.local/bin" go install github.com/dmikalova/project-standards/cmd/project-standards@latest

echo "installing node via nvm"
export NVM_DIR="${HOME}/.nvm"
mkdir -p "${NVM_DIR}"
# shellcheck disable=SC1091
. "/opt/homebrew/opt/nvm/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
corepack enable
