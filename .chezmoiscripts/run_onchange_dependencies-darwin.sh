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
	"docker" \
	"eza" \
	"fd" \
	"fzf" \
	"gh" \
	"ghostty" \
	"git" \
	"git-delta" \
	"gnupg" \
	"golang" \
	"gum" \
	"govulncheck" \
	"hunk" \
	"jq" \
	"jqp" \
	"lefthook" \
	"mage" \
	"moor" \
	"neovim" \
	"nmap" \
	"meetingbar" \
	"nvm" \
	"opentofu" \
	"ouch" \
	"pinentry-mac" \
	"postgresql@15" \
	"pulumi" \
	"ripgrep" \
	"shellcheck" \†
	"shfmt" \
	"slack" \
	"sops" \
	"starship" \
	"terramate" \
	"tree-sitter-cli" \
	"uv" \
	"xorriso" \
	"zellij" \
	"zoxide"

brew install --cask \
	"bitwarden" \
	"discord" \
	"docker-desktop" \
	"font-sauce-code-pro-nerd-font" \
	"google-cloud-sdk" \
	"hammerspoon" \
	"linearmouse" \
	"logitune" \
	"notion" \
	"obsidian" \
	"signal" \
	"tailscale-app" \
	"visual-studio-code" \
	"zoom"

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
