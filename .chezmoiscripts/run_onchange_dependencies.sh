#!/bin/sh

echo "installing apt packages"
sudo apt install \
    "catimg" \
    "chroma" \
    "fd-find" \
    "fzf" \
    "inotify-tools" \
    "kwalletcli" \
    "pinentry-tty" \
    "thefuck" \
    "xclip"

echo "installing go packages"
go install "github.com/dmikalova/brocket"

echo "installing global npm packages"
npm install --global "trash-cli"

echo "installing snaps"
sudo snap install --classic "chezmoi"
sudo snap install "bitwarden"
sudo snap install "bw"

# tf, tflint, tg, hcledit
# consul
# go get -u github.com/dirk/quickhook
# docker
# enpass
# exfat
# git
# go_1_12
# firefox
# libsecret
# nodejs-10_x
# nomad
# packer
# shellchec
# steam
# unzip
# vault
# vscode
# wget
# wmctrl
# xclip
# xdotool

# Monospaced: Noto mono
# Normal: Noto sans

# libnotify-bin
# cmake
# nvidia-driver-450
# qtdeclarative5-dev
# libc++1
# playerctl
# /home/dmikalova/downloads/discord-0.0.13.deb
# awscli
# node-grunt-cli
# simpleburn
# libkf5cddbwidgets5
# plantuml
# golang-go
# ardour
# soundkonverter
# finger
# byobu
# docker
# apt-transport-https ca-certificates curl gnupg lsb-release
# docker-ce docker-ce-cli containerd.io
# firefox
# terraform-ls
# terraform
# kubectl
# pgadmin3
# apache2-utils
# gtk3-nocsd
# nodejs
# steam
# xsel
# s3cmd
# gtk3-nocsd
# gtk3-nocsd
# gnome-keyring
# libusb-dev
# pdftk
# surf
# chromium-browser
# cloc
# seahorse
# git-all
# git
# gh
# zsh
# /home/dmikalova/downloads/code_1.62.2-1636665017_amd64.deb
# /home/dmikalova/downloads/extraterm_0.59.3_amd64.deb
# fish
# colortest
# colordiff
# fzf
# fd-find fzf
# catimg
# chroma
# xclip
# ripgrep
# thefuck
# atool
# kwalletcli
# pinentry-tty
# golang
# gnome-keyring
# inotify-tools
