#!/bin/sh

file='[General]
showlogo=hidden
logo=/usr/share/sddm/themes/breeze/default-logo.svg
type=image
color=#cddc39
fontSize=10
background=/usr/share/wallpapers/dmikalova/wallpaper
needsFullUserModel=false
'
echo "$file" | sudo dd status=none of="/usr/share/sddm/themes/breeze/theme.conf"
