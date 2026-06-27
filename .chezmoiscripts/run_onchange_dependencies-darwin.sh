#!/bin/sh
# macOS dependencies installed via Homebrew

echo "installing brew packages"
brew install \
    "age" \
    "catimg" \
    "chezmoi" \
    "chroma" \
    "cloc" \
    "coreutils" \
    "deno" \
    "direnv" \
    "fd" \
    "fzf" \
    "gh" \
    "git" \
    "gnupg" \
    "jq" \
    "opentofu" \
    "pinentry-mac" \
    "ripgrep" \
    "shellcheck" \
    "sops" \
    "trash-cli"

brew install --cask \
    "bitwarden" \
    "hammerspoon" \
    "warp"
