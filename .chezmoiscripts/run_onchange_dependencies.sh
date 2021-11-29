#!/bin/sh

echo "installing apt packages"
sudo apt install \
    "catimg" \
    "chroma" \
    "cloc" \
    "curl" \
    "docker" \
    "fd-find" \
    "fonts-noto-color-emoji" \
    "fonts-noto-core" \
    "fonts-noto-mono" \
    "fzf" \
    "inotify-tools" \
    "kwalletcli" \
    "pinentry-tty" \
    "playerctl" \
    "ripgrep" \
    "thefuck" \
    "unzip" \
    "wget" \
    "xclip"

echo "installing go packages"
go install "github.com/dmikalova/brocket"

echo "installing global npm packages"
npm install --global "trash-cli"

# apache2-utils
# apt-transport-https
# ardour
# atool
# ca-certificates
# cmake
# colordiff
# colortest
# discord
# exfat
# fd-find
# ffmpeg
# finger
# firefox
# fzf
# gh
# git
# gnome
# gnome-keyring
# gnupg
# gtk-common-themes
# gtk3-nocsd
# inotify-tools
# kubectl
# kwalletcli
# libkf5cddbwidgets5
# libnotify-bin
# libsecret
# libusb-dev
# lsb-release
# nodejs
# nodejs-10_x
# pgadmin3
# pinentry-tty
# plantuml
# s3cmd
# simpleburn
# soundkonverter
# steam
# terraform-ls
# vscode
# zsh
