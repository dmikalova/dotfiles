#!/bin/sh

file='# /etc/X11/xorg.conf.d/50-kensington-mouse.conf
# https://www.x.org/releases/current/doc/man/man5/xorg.conf.5.xhtml

Section "InputClass"
    Identifier   "Kensington Expert Mouse"
    MatchProduct "Kensington"
    Driver       "evdev
    Option       "AccelerationNumerator" "8"
    Option       "AccelerationDenominator" "1"
    Option       "AccelerationThreshold" "4"
    Option       "AdaptiveDeceleration" "2"
    Option       "ButtonMapping" "3 2 1 4 5 6 7 2"
EndSection
'
echo "$file" | sudo dd status=none of="/etc/X11/xorg.conf.d/50-kensington-mouse.conf"
