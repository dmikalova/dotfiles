#!/bin/sh

echo "installing apt packages"
sudo apt install \
    catimg \
    chroma \
    fd-find \
    fzf \
    kwalletcli \
    pinentry-tty \
    thefuck \
    xclip

echo "installing go packages"

echo "installing global npm packages"
npm install --global trash-cli

echo "installing snaps"
sudo snap install chezmoi --classic
sudo snap install bitwarden
sudo snap install bw

# tf, tflint, tg, hcledit
# consul
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
# shellcheck
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
